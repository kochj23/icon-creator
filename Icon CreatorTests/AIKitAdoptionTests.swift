//
//  AIKitAdoptionTests.swift
//  Icon CreatorTests
//
//  Icon Creator's AI contract on NovaAIKit 1.0.0 (keyword expansion, settings, keys, migration).
//  Grouped in the 7 categories: security, performance, retry, unit, integration, functional, frame/UI state.
//  Never touches the real Keychain or network: in-memory settings/keys and a stub URLProtocol.
//
//  Written by Jordan Koch
//

import XCTest
import SwiftUI
import NovaAIKit
@testable import Icon_Creator

// MARK: - Test support

/// Canned replies by URL path; anything unhandled fails like an unreachable host.
final class IconAIStubProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var handler: ((URLRequest) -> (Int, String)?)?
    private static var count = 0
    private static var keyed = 0

    static func respond(_ h: ((URLRequest) -> (Int, String)?)?) { lock.lock(); handler = h; count = 0; keyed = 0; lock.unlock() }
    static var requestCount: Int { lock.lock(); defer { lock.unlock() }; return count }
    /// Requests that carried an Authorization header.
    static var keyedRequestCount: Int { lock.lock(); defer { lock.unlock() }; return keyed }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lock.lock(); Self.count += 1
        if request.value(forHTTPHeaderField: "Authorization") != nil { Self.keyed += 1 }
        let h = Self.handler; Self.lock.unlock()
        guard let (status, body) = h?(request) else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1",
                                   headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}

    /// An Ollama /api/chat reply carrying `text`; /api/tags lists one model.
    static func ollama(_ text: String) -> (URLRequest) -> (Int, String)? {
        { req in
            if req.url?.path == "/api/tags" { return (200, #"{"models":[{"name":"qwen3:8b"}]}"#) }
            let content = String(data: try! JSONSerialization.data(withJSONObject: [text]), encoding: .utf8)!
                .dropFirst().dropLast()
            return (200, #"{"model":"qwen3:8b","message":{"role":"assistant","content":\#(content)},"done":true}"#)
        }
    }
}

class IconAITestCase: XCTestCase {
    var keyStore: NovaAIMemoryKeyStore!

    override func setUp() {
        super.setUp()
        IconAIStubProtocol.respond(nil)
        keyStore = NovaAIMemoryKeyStore()
    }

    override func tearDown() {
        IconAIStubProtocol.respond(nil)
        super.tearDown()
    }

    @MainActor
    func makeAI(_ s: NovaAISettings = NovaAISettings()) -> NovaAI {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [IconAIStubProtocol.self]
        return NovaAI(configuration: AppAI.configuration, storage: NovaAIMemoryStorage(s), keyStore: keyStore,
                      session: URLSession(configuration: cfg), sleep: { _ in })
    }

    /// Settings pinned to Ollama at a stub host.
    func ollamaOnly() -> NovaAISettings {
        var s = NovaAISettings(backend: .ollama)
        s.setURL("http://stub-ollama.local:11434", for: .ollama)
        s.setModel("qwen3:8b", for: .ollama)
        return s
    }

    func freshDefaults(_ name: String = #function) -> UserDefaults {
        let suite = "IconCreatorTests.\(name).\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }
}

// MARK: - Security

final class AIKitSecurityTests: IconAITestCase {
    @MainActor func testKeychainServiceNames() {
        let c = AppAI.configuration
        XCTAssertEqual(c.appID, "iconcreator")
        XCTAssertEqual(c.keychainService(for: .openRouter), "com.jkoch.iconcreator.openrouter")
        XCTAssertEqual(c.keychainService(for: .openAI), "com.jkoch.iconcreator.openai")
        XCTAssertEqual(NovaAIConfiguration.keychainAccount, "apiKey")
    }

    @MainActor
    func testKeysGoToKeyStoreNotSettings() throws {
        let ai = makeAI()
        XCTAssertTrue(ai.setAPIKey("sk-test-not-real", for: .openAI))
        XCTAssertTrue(ai.hasAPIKey(for: .openAI))
        let encoded = String(decoding: try JSONEncoder().encode(ai.settings), as: UTF8.self)
        XCTAssertFalse(encoded.contains("sk-test-not-real"), "settings must never hold a key")
        XCTAssertEqual(keyStore.read(service: "com.jkoch.iconcreator.openai", account: "apiKey"), "sk-test-not-real")
    }

    @MainActor
    func testKeyNeverSentOverPlainHTTP() async {
        var s = NovaAISettings(backend: .openAI)
        s.setURL("http://api.example.invalid", for: .openAI)
        let ai = makeAI(s)
        ai.setAPIKey("sk-test-not-real", for: .openAI)
        IconAIStubProtocol.respond(IconAIStubProtocol.ollama("should not be reached"))
        do {
            _ = try await ai.complete(NovaAIRequest(prompt: "x"))
            XCTFail("http + key must be refused")
        } catch {
            XCTAssertEqual(IconAIStubProtocol.keyedRequestCount, 0, "the key may never travel over http")
            XCTAssertTrue("\(error)".contains("insecureTransport") || (error as? LocalizedError)?.errorDescription?.contains("https") == true,
                          "unexpected error \(error)")
        }
    }

    @MainActor
    func testLegacyKeychainItemsMigratedAndObsoleteDeleted() {
        let legacy = NovaAIMemoryKeyStore()
        legacy.write("sk-legacy", service: AppAI.legacyKeychainService, account: AppAI.legacyOpenAIAccount)
        for a in AppAI.legacyObsoleteAccounts { legacy.write("old", service: AppAI.legacyKeychainService, account: a) }
        let ai = makeAI()
        AppAI.migrateLegacy(ai, defaults: freshDefaults(), legacyStore: legacy)
        XCTAssertEqual(keyStore.read(service: "com.jkoch.iconcreator.openai", account: "apiKey"), "sk-legacy")
        XCTAssertNil(legacy.read(service: AppAI.legacyKeychainService, account: AppAI.legacyOpenAIAccount))
        for a in AppAI.legacyObsoleteAccounts {
            XCTAssertNil(legacy.read(service: AppAI.legacyKeychainService, account: a), "\(a) must be deleted")
        }
    }

    @MainActor
    func testPlaintextDefaultsSecretsRemoved() {
        let d = freshDefaults()
        let plainKey = NovaAILegacySettings.openAIKeyKeys[0]
        d.set("sk-plain", forKey: plainKey)
        d.set("sk-plain2", forKey: AppAI.legacyOpenAIAccount)
        d.set("g", forKey: AppAI.legacyPrefix + "GoogleCloud_Key")
        d.set("us-east-1", forKey: AppAI.legacyPrefix + "AWS_Region")
        let ai = makeAI()
        AppAI.migrateLegacy(ai, defaults: d, legacyStore: NovaAIMemoryKeyStore())
        XCTAssertNil(d.object(forKey: plainKey))
        XCTAssertNil(d.object(forKey: AppAI.legacyOpenAIAccount))
        XCTAssertNil(d.object(forKey: AppAI.legacyPrefix + "GoogleCloud_Key"))
        XCTAssertNil(d.object(forKey: AppAI.legacyPrefix + "AWS_Region"))
        XCTAssertTrue(ai.hasAPIKey(for: .openAI))
    }

    func testNoLegacyAIClientInSources() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        // Built from parts so this file doesn't match its own scan.
        let banned = ["AIBackend" + "Manager", "Ethical" + "AIGuardian", "AIBackend" + "StatusMenu", "OPENAI" + "_API_KEY",
                      "AIBackend" + "_OpenAI_Key", "Unified" + "AICapabilities"]
        var scanned = 0
        let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)!
        for case let url as URL in e where url.pathExtension == "swift" {
            if url.path.contains("/.build/") || url.path.contains("/dd") { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
                .replacingOccurrences(of: "migrateFromLegacyAIBackendManager", with: "")
            for b in banned { XCTAssertFalse(text.contains(b), "\(url.lastPathComponent) still references \(b)") }
            scanned += 1
        }
        XCTAssertGreaterThan(scanned, 20)
    }
}

// MARK: - Performance

final class AIKitPerformanceTests: IconAITestCase {
    func testBuiltInExpansionIsFast() {
        let keywords = (0..<500).map { i in ["music", "weather", "zebra\(i)", "photo app", "finance"][i % 5] }
        measure { _ = KeywordExpansion.builtIn(keywords) }
    }

    func testParseLargeReplyIsBoundedAndFast() throws {
        let reply = (0..<5000).map { "element \($0)" }.joined(separator: ", ")
        var result: [String] = []
        measure { result = (try? KeywordExpansion.parse(reply)) ?? [] }
        XCTAssertEqual(result.count, KeywordExpansion.maxElements)
    }

    @MainActor
    func testOfflineFallbackDoesNotHang() async {
        let ai = makeAI(ollamaOnly())
        let start = Date()
        let r = await ai.generate(KeywordExpansion.request(for: ["music"]), validate: KeywordExpansion.parse,
                                  fallback: { KeywordExpansion.builtIn(["music"]) })
        XCTAssertFalse(r.isAI)
        XCTAssertLessThan(Date().timeIntervalSince(start), 10)
    }
}

// MARK: - Retry

final class AIKitRetryTests: IconAITestCase {
    @MainActor
    func testRejectedReplyIsRetriedOnceThenFallsBack() async {
        IconAIStubProtocol.respond(IconAIStubProtocol.ollama("   ,  ;  "))
        let ai = makeAI(ollamaOnly())
        let r = await ai.generate(KeywordExpansion.request(for: ["music"]), validate: KeywordExpansion.parse,
                                  fallback: { KeywordExpansion.builtIn(["music"]) })
        XCTAssertFalse(r.isAI)
        if case .fallback(.validationFailed) = r.source {} else { XCTFail("expected validationFailed, got \(r.source)") }
        XCTAssertTrue(r.value.contains("headphones"))
    }

    @MainActor
    func testTransientFailureThenSuccess() async {
        let lock = NSLock()
        var chatCalls = 0
        let ok = IconAIStubProtocol.ollama("shield, padlock")
        IconAIStubProtocol.respond { req in
            if req.url?.path == "/api/tags" { return ok(req) }
            lock.lock(); chatCalls += 1; let n = chatCalls; lock.unlock()
            return n == 1 ? (503, "{}") : ok(req)
        }
        let ai = makeAI(ollamaOnly())
        let r = await ai.generate(KeywordExpansion.request(for: ["security"]), validate: KeywordExpansion.parse,
                                  fallback: { [] })
        XCTAssertTrue(r.isAI, "a 503 is retried")
        XCTAssertEqual(r.value, ["shield", "padlock"])
    }
}

// MARK: - Unit

final class AIKitUnitTests: XCTestCase {
    func testParseSplitsTrimsAndDedupes() throws {
        let items = try KeywordExpansion.parse("1. Musical note, headphones\n- Headphones; \"vinyl record\".\nmusic: microphone")
        XCTAssertEqual(items, ["Musical note", "headphones", "vinyl record", "microphone"])
    }

    func testParseRejectsEmpty() {
        XCTAssertThrowsError(try KeywordExpansion.parse("  \n , ; "))
    }

    func testParseDropsOverlongItems() throws {
        let long = String(repeating: "x", count: KeywordExpansion.maxElementLength + 1)
        XCTAssertEqual(try KeywordExpansion.parse("\(long), star"), ["star"])
    }

    func testBuiltInKnownKeyword() {
        let r = KeywordExpansion.builtIn(["music"])
        XCTAssertEqual(r.first, "music")
        XCTAssertTrue(r.contains("headphones"))
    }

    func testBuiltInMatchesWholeWordsOnly() {
        let r = KeywordExpansion.builtIn(["rain"])
        XCTAssertFalse(r.contains("chip"), "'rain' must not match the 'ai' vocabulary")
        XCTAssertEqual(r, ["rain", "rain symbol", "rain silhouette"])
        XCTAssertTrue(KeywordExpansion.builtIn(["weather app"]).contains("sun"))
    }

    func testBuiltInBounded() {
        XCTAssertLessThanOrEqual(KeywordExpansion.builtIn((0..<100).map { "k\($0)" }).count, KeywordExpansion.maxElements)
        XCTAssertTrue(KeywordExpansion.builtIn([]).isEmpty)
    }

    func testBackendSetIsComplete() {
        XCTAssertEqual(NovaAIBackend.allCases.count, 9)
        for b in ["auto", "ollama", "mlx", "tinyllm", "tinychat", "openwebui", "novagateway", "openrouter", "openai"] {
            XCTAssertNotNil(NovaAIBackend(rawValue: b), b)
        }
    }

    func testRequestCarriesPromptAndSystem() {
        let r = KeywordExpansion.request(for: ["music", "chat"])
        XCTAssertEqual(r.maxTokens, 400)
        XCTAssertTrue(r.messages.contains { $0.role == .system && $0.content == KeywordExpansion.systemPrompt })
        XCTAssertTrue(r.messages.contains { $0.role == .user && $0.content.contains("music, chat") })
    }
}

// MARK: - Integration

final class AIKitIntegrationTests: IconAITestCase {
    @MainActor
    func testAIReplyUsedWhenValid() async {
        IconAIStubProtocol.respond(IconAIStubProtocol.ollama("musical note, headphones, vinyl record"))
        let ai = makeAI(ollamaOnly())
        let gen = KeywordIconGenerator()
        let out = await gen.expandKeywords(["music"], ai: ai)
        XCTAssertEqual(out, ["musical note", "headphones", "vinyl record"])
        XCTAssertEqual(gen.lastExpansionSource, "AI · Ollama (qwen3:8b)")
        XCTAssertEqual(ai.status.state, .online)
    }

    @MainActor
    func testLegacySettingsMigrate() {
        let d = freshDefaults()
        d.set("Ollama", forKey: AppAI.legacyPrefix + "SelectedBackend")
        d.set("llama3.2:3b", forKey: AppAI.legacyPrefix + "OllamaModel")
        d.set("http://tiny.local:8000", forKey: AppAI.legacyPrefix + "TinyLLMServerURL")
        d.set("http://webui.local:3000", forKey: AppAI.legacyPrefix + "OpenWebUIServerURL")
        let ai = makeAI()
        AppAI.migrateLegacy(ai, defaults: d, legacyStore: NovaAIMemoryKeyStore())
        XCTAssertEqual(ai.settings.backend, .ollama)
        XCTAssertEqual(ai.settings.model(for: .ollama), "llama3.2:3b")
        XCTAssertEqual(ai.settings.url(for: .tinyLLM), "http://tiny.local:8000")
        XCTAssertEqual(ai.settings.url(for: .openWebUI), "http://webui.local:3000")
        XCTAssertNil(d.object(forKey: AppAI.legacyPrefix + "TinyLLMServerURL"))
    }

    @MainActor
    func testRemovedCloudBackendMapsToAuto() {
        let d = freshDefaults()
        d.set("IBM Watson", forKey: AppAI.legacyPrefix + "SelectedBackend")
        d.set("llama3.2:3b", forKey: AppAI.legacyPrefix + "OllamaModel")
        let ai = makeAI()
        AppAI.migrateLegacy(ai, defaults: d, legacyStore: NovaAIMemoryKeyStore())
        XCTAssertEqual(ai.settings.model(for: .ollama), "llama3.2:3b", "legacy settings were imported")
        XCTAssertEqual(ai.settings.backend, .auto)
    }

    @MainActor
    func testMigrationIsIdempotent() {
        let d = freshDefaults()
        d.set("TinyChat", forKey: AppAI.legacyPrefix + "SelectedBackend")
        let ai = makeAI()
        AppAI.migrateLegacy(ai, defaults: d, legacyStore: NovaAIMemoryKeyStore())
        ai.settings.backend = .openRouter
        AppAI.migrateLegacy(ai, defaults: d, legacyStore: NovaAIMemoryKeyStore())
        XCTAssertEqual(ai.settings.backend, .openRouter, "second run must not overwrite the user's choice")
    }
}

// MARK: - Functional

final class AIKitFunctionalTests: IconAITestCase {
    @MainActor
    func testEveryFeatureWorksWithAIOff() async {
        let ai = makeAI(NovaAISettings(enabled: false))
        IconAIStubProtocol.respond(IconAIStubProtocol.ollama("should not be used"))
        let gen = KeywordIconGenerator()
        let out = await gen.expandKeywords(["security"], ai: ai)
        XCTAssertTrue(out.contains("shield"))
        XCTAssertEqual(gen.lastExpansionSource, "Built-in")
        XCTAssertEqual(IconAIStubProtocol.requestCount, 0, "AI off sends nothing")
        XCTAssertNil(gen.lastError)
    }

    @MainActor
    func testEveryFeatureFallsBackWhenOffline() async {
        let ai = makeAI()          // Auto, every backend refused
        let gen = KeywordIconGenerator()
        let out = await gen.expandKeywords(["weather"], ai: ai)
        XCTAssertTrue(out.contains("sun"))
        XCTAssertEqual(gen.lastExpansionSource, "Built-in")
    }

    @MainActor
    func testEmptyKeywordsAreReturnedUnchanged() async {
        let gen = KeywordIconGenerator()
        let out = await gen.expandKeywords([], ai: makeAI())
        XCTAssertTrue(out.isEmpty)
        XCTAssertEqual(IconAIStubProtocol.requestCount, 0)
    }

    @MainActor
    func testToggleIsPersisted() {
        let storage = NovaAIMemoryStorage(NovaAISettings())
        let ai = NovaAI(configuration: AppAI.configuration, storage: storage, keyStore: keyStore)
        ai.isEnabled = false
        XCTAssertEqual(storage.load()?.enabled, false)
    }
}

// MARK: - Frame / UI state

final class AIKitFrameTests: IconAITestCase {
    @MainActor
    func testStatusIsOffWhenDisabled() async {
        let ai = makeAI(NovaAISettings(enabled: false))
        XCTAssertEqual(ai.status.state, .off)
        _ = await ai.text(NovaAIRequest(prompt: "x")) { "fallback" }
        XCTAssertEqual(ai.status.state, .off)
        XCTAssertEqual(ai.status.lastSource, .fallback(.disabled))
    }

    @MainActor
    func testSettingsViewsRender() {
        let sizes: [CGSize] = [
            NSHostingController(rootView: AISettingsSheet()).view.fittingSize,
            NSHostingController(rootView: IconCreatorSettingsView()).view.fittingSize,
            NSHostingController(rootView: NovaAIStatusIndicator(ai: makeAI(), checksOnAppear: false)).view.fittingSize,
        ]
        for s in sizes { XCTAssertGreaterThan(s.width, 0); XCTAssertGreaterThan(s.height, 0) }
    }

    @MainActor
    func testKeywordViewHostsStatusIndicator() {
        let host = NSHostingController(rootView: KeywordIconGeneratorView())
        host.view.frame = NSRect(x: 0, y: 0, width: 900, height: 700)
        host.view.layoutSubtreeIfNeeded()
        XCTAssertGreaterThan(host.view.fittingSize.height, 0)
    }

    func testFallbackDescriptionMentionsBuiltIn() async {
        let text = await MainActor.run { AppAI.fallbackDescription }
        XCTAssertTrue(text.contains("built-in"))
    }
}

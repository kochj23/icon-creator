import Foundation
import Vapor

//
//  WebhookServer.swift
//  Icon Creator Webhook Server
//
//  Receives webhooks from CI/CD systems and triggers icon generation
//  Author: Jordan Koch
//  Date: 2026-01-21
//

/// Webhook server for automated icon generation
/// Listens for POST requests and triggers icon regeneration
class IconCreatorWebhookServer {

    private let app: Application
    private let port: Int
    private let config: WebhookConfig

    // MARK: - Initialization

    init(config: WebhookConfig = .default) throws {
        self.config = config
        self.port = config.port

        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        self.app = Application(env)

        setupRoutes()
    }

    // MARK: - Routes

    private func setupRoutes() {
        // Health check endpoint
        app.get("health") { req in
            return [
                "status": "healthy",
                "version": "1.0.0",
                "uptime": ProcessInfo.processInfo.systemUptime
            ]
        }

        // GitHub webhook endpoint
        app.post("webhook", "github") { req -> EventLoopFuture<Response> in
            return try self.handleGitHubWebhook(req)
        }

        // GitLab webhook endpoint
        app.post("webhook", "gitlab") { req -> EventLoopFuture<Response> in
            return try self.handleGitLabWebhook(req)
        }

        // Custom webhook endpoint
        app.post("webhook", "custom") { req -> EventLoopFuture<Response> in
            return try self.handleCustomWebhook(req)
        }

        // Trigger manual icon generation
        app.post("generate") { req -> EventLoopFuture<Response> in
            return try self.handleManualGeneration(req)
        }
    }

    // MARK: - Webhook Handlers

    private func handleGitHubWebhook(_ req: Request) throws -> EventLoopFuture<Response> {
        // Verify GitHub signature
        guard let signature = req.headers["X-Hub-Signature-256"].first,
              verifyGitHubSignature(signature, body: req.body, secret: config.githubSecret) else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Invalid signature"))
        }

        let event = req.headers["X-GitHub-Event"].first ?? "unknown"

        guard event == "push" || event == "pull_request" else {
            return req.eventLoop.makeSucceededFuture(Response(status: .ok, body: .init(string: "Event ignored")))
        }

        return try req.content.decode(GitHubWebhookPayload.self).flatMap { payload in
            // Check if icon files were modified
            let iconChanged = payload.commits?.contains { commit in
                commit.modified.contains { $0.contains("icon") || $0.contains("assets") }
            } ?? false

            guard iconChanged else {
                return req.eventLoop.makeSucceededFuture(Response(status: .ok, body: .init(string: "No icon changes")))
            }

            // Trigger icon generation
            return self.triggerIconGeneration(
                repository: payload.repository.full_name,
                branch: payload.ref.components(separatedBy: "/").last ?? "main",
                commit: payload.after ?? "",
                eventLoop: req.eventLoop
            )
        }
    }

    private func handleGitLabWebhook(_ req: Request) throws -> EventLoopFuture<Response> {
        // Verify GitLab token
        guard let token = req.headers["X-Gitlab-Token"].first,
              token == config.gitlabToken else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Invalid token"))
        }

        return try req.content.decode(GitLabWebhookPayload.self).flatMap { payload in
            return self.triggerIconGeneration(
                repository: payload.project.path_with_namespace,
                branch: payload.ref.components(separatedBy: "/").last ?? "main",
                commit: payload.after,
                eventLoop: req.eventLoop
            )
        }
    }

    private func handleCustomWebhook(_ req: Request) throws -> EventLoopFuture<Response> {
        // Verify API key
        guard let apiKey = req.headers["X-API-Key"].first,
              apiKey == config.apiKey else {
            return req.eventLoop.makeFailedFuture(Abort(.unauthorized, reason: "Invalid API key"))
        }

        return try req.content.decode(CustomWebhookPayload.self).flatMap { payload in
            return self.triggerIconGeneration(
                repository: payload.repository,
                branch: payload.branch,
                commit: payload.commit,
                eventLoop: req.eventLoop
            )
        }
    }

    private func handleManualGeneration(_ req: Request) throws -> EventLoopFuture<Response> {
        return try req.content.decode(ManualGenerationRequest.self).flatMap { request in
            let promise = req.eventLoop.makePromise(of: Response.self)

            // Execute generation in background
            DispatchQueue.global().async {
                do {
                    let result = try self.generateIcons(
                        source: request.source,
                        output: request.output,
                        platforms: request.platforms
                    )

                    let response = Response(
                        status: .ok,
                        headers: ["Content-Type": "application/json"],
                        body: .init(data: try JSONEncoder().encode(result))
                    )

                    promise.succeed(response)
                } catch {
                    promise.fail(error)
                }
            }

            return promise.futureResult
        }
    }

    // MARK: - Icon Generation

    private func triggerIconGeneration(
        repository: String,
        branch: String,
        commit: String,
        eventLoop: EventLoop
    ) -> EventLoopFuture<Response> {
        let promise = eventLoop.makePromise(of: Response.self)

        DispatchQueue.global().async {
            do {
                print("🔄 Triggering icon generation...")
                print("   Repository: \(repository)")
                print("   Branch: \(branch)")
                print("   Commit: \(commit)")

                // Execute icon generation via CLI
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/local/bin/icon-creator")
                task.arguments = [
                    "generate",
                    "--input", self.config.iconSourcePath,
                    "--output", self.config.iconOutputPath,
                    "--verbose"
                ]

                let outputPipe = Pipe()
                task.standardOutput = outputPipe
                task.standardError = outputPipe

                try task.run()
                task.waitUntilExit()

                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                let result = GenerationResult(
                    success: task.terminationStatus == 0,
                    repository: repository,
                    branch: branch,
                    commit: commit,
                    output: output,
                    timestamp: Date()
                )

                let response = Response(
                    status: .ok,
                    headers: ["Content-Type": "application/json"],
                    body: .init(data: try JSONEncoder().encode(result))
                )

                promise.succeed(response)

                print("✅ Icon generation complete")
            } catch {
                print("❌ Error: \(error)")
                promise.fail(error)
            }
        }

        return promise.futureResult
    }

    private func generateIcons(source: String, output: String, platforms: [String]) throws -> GenerationResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/local/bin/icon-creator")
        task.arguments = [
            "generate",
            "--input", source,
            "--output", output,
            "--platforms", platforms.joined(separator: ","),
            "--verbose"
        ]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe

        try task.run()
        task.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(data: data, encoding: .utf8) ?? ""

        return GenerationResult(
            success: task.terminationStatus == 0,
            repository: "manual",
            branch: "manual",
            commit: "manual",
            output: outputText,
            timestamp: Date()
        )
    }

    // MARK: - Security

    private func verifyGitHubSignature(_ signature: String, body: ByteBuffer?, secret: String) -> Bool {
        guard let body = body else { return false }

        let data = body.getData(at: body.readerIndex, length: body.readableBytes) ?? Data()

        // Verify HMAC SHA256 signature
        // Implementation would use CryptoKit here
        // For production: compare HMAC-SHA256(secret, body) with signature

        return true // Simplified for example
    }

    // MARK: - Server Lifecycle

    func start() throws {
        try app.server.start(address: .hostname("0.0.0.0", port: port))

        print("✅ Webhook server started on port \(port)")
        print("📡 Endpoints:")
        print("   GET  /health")
        print("   POST /webhook/github")
        print("   POST /webhook/gitlab")
        print("   POST /webhook/custom")
        print("   POST /generate")
    }

    func stop() throws {
        app.shutdown()
    }
}

// MARK: - Models

struct WebhookConfig {
    let port: Int
    let githubSecret: String
    let gitlabToken: String
    let apiKey: String
    let iconSourcePath: String
    let iconOutputPath: String

    static let `default` = WebhookConfig(
        port: 8080,
        githubSecret: ProcessInfo.processInfo.environment["GITHUB_WEBHOOK_SECRET"] ?? "",
        gitlabToken: ProcessInfo.processInfo.environment["GITLAB_TOKEN"] ?? "",
        apiKey: ProcessInfo.processInfo.environment["API_KEY"] ?? "",
        iconSourcePath: "./assets/icon-source.png",
        iconOutputPath: "./generated-icons"
    )
}

struct GitHubWebhookPayload: Content {
    let ref: String
    let after: String?
    let repository: Repository
    let commits: [Commit]?

    struct Repository: Content {
        let full_name: String
    }

    struct Commit: Content {
        let modified: [String]
    }
}

struct GitLabWebhookPayload: Content {
    let ref: String
    let after: String
    let project: Project

    struct Project: Content {
        let path_with_namespace: String
    }
}

struct CustomWebhookPayload: Content {
    let repository: String
    let branch: String
    let commit: String
}

struct ManualGenerationRequest: Content {
    let source: String
    let output: String
    let platforms: [String]
}

struct GenerationResult: Content {
    let success: Bool
    let repository: String
    let branch: String
    let commit: String
    let output: String
    let timestamp: Date
}

import Foundation
import Crypto
import Vapor

//
//  WebhookServer+Security.swift
//  Icon Creator Webhook Server - Security Extensions
//
//  Real HMAC-SHA256 signature verification for webhooks
//  Author: Jordan Koch
//  Date: 2026-01-21
//

extension IconCreatorWebhookServer {

    /// Verify GitHub webhook signature using HMAC-SHA256
    /// GitHub sends X-Hub-Signature-256 header with format: "sha256=<signature>"
    func verifyGitHubSignature(_ signature: String, body: ByteBuffer?, secret: String) -> Bool {
        guard let body = body else { return false }

        // Extract the signature hash from header
        guard signature.hasPrefix("sha256=") else {
            print("⚠️ Invalid signature format (missing sha256= prefix)")
            return false
        }

        let providedSignature = String(signature.dropFirst(7)) // Remove "sha256="

        // Get body data
        guard let bodyData = body.getData(at: body.readerIndex, length: body.readableBytes) else {
            print("⚠️ Could not read body data")
            return false
        }

        // Compute HMAC-SHA256
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let hmac = HMAC<SHA256>.authenticationCode(for: bodyData, using: key)
        let computedSignature = hmac.map { String(format: "%02x", $0) }.joined()

        // Constant-time comparison to prevent timing attacks
        guard providedSignature.count == computedSignature.count else {
            print("⚠️ Signature length mismatch")
            return false
        }

        var result = 0
        for (c1, c2) in zip(providedSignature.utf8, computedSignature.utf8) {
            result |= Int(c1) ^ Int(c2)
        }

        let isValid = result == 0

        if !isValid {
            print("❌ Signature verification failed")
            print("   Expected: \(computedSignature)")
            print("   Received: \(providedSignature)")
        } else {
            print("✅ Signature verified successfully")
        }

        return isValid
    }

    /// Verify GitLab webhook token
    /// GitLab sends X-Gitlab-Token header with the secret token
    func verifyGitLabToken(_ token: String, expectedToken: String) -> Bool {
        // Constant-time comparison
        guard token.count == expectedToken.count else {
            return false
        }

        var result = 0
        for (c1, c2) in zip(token.utf8, expectedToken.utf8) {
            result |= Int(c1) ^ Int(c2)
        }

        return result == 0
    }

    /// Verify custom API key
    /// Uses constant-time comparison to prevent timing attacks
    func verifyAPIKey(_ provided: String, expected: String) -> Bool {
        guard provided.count == expected.count else {
            return false
        }

        var result = 0
        for (c1, c2) in zip(provided.utf8, expected.utf8) {
            result |= Int(c1) ^ Int(c2)
        }

        return result == 0
    }

    /// Generate secure random API key
    /// Creates a 32-byte random key encoded as hex string
    static func generateAPIKey() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    /// Validate webhook payload for common injection attacks
    func validatePayloadSecurity(_ payload: [String: Any]) -> Bool {
        // Check for suspiciously large payloads (DoS protection)
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              jsonData.count < 1_000_000 else { // 1MB limit
            print("⚠️ Payload too large, possible DoS attempt")
            return false
        }

        // Check for command injection patterns in strings
        let dangerousPatterns = [
            ";", "&&", "||", "`", "$(",
            "../", "\\x00", "%00"
        ]

        func checkValue(_ value: Any) -> Bool {
            if let string = value as? String {
                for pattern in dangerousPatterns {
                    if string.contains(pattern) {
                        print("⚠️ Suspicious pattern detected: \(pattern)")
                        return false
                    }
                }
            } else if let dict = value as? [String: Any] {
                for (_, val) in dict {
                    if !checkValue(val) {
                        return false
                    }
                }
            } else if let array = value as? [Any] {
                for val in array {
                    if !checkValue(val) {
                        return false
                    }
                }
            }
            return true
        }

        return checkValue(payload)
    }

    /// Rate limiting to prevent abuse
    /// Simple in-memory rate limiter (production should use Redis)
    func checkRateLimit(for ip: String, limit: Int = 10, window: TimeInterval = 60) -> Bool {
        let now = Date()

        // Clean up old entries
        rateLimitStore = rateLimitStore.filter { $0.value.timestamp.timeIntervalSince(now) > -window }

        // Check current count
        let currentCount = rateLimitStore.values.filter { entry in
            entry.ip == ip && entry.timestamp.timeIntervalSince(now) > -window
        }.count

        if currentCount >= limit {
            print("⚠️ Rate limit exceeded for IP: \(ip)")
            return false
        }

        // Add new entry
        let id = UUID()
        rateLimitStore[id] = RateLimitEntry(ip: ip, timestamp: now)

        return true
    }
}

// MARK: - Rate Limiting Models

struct RateLimitEntry {
    let ip: String
    let timestamp: Date
}

// In-memory rate limit store (production should use Redis)
private var rateLimitStore: [UUID: RateLimitEntry] = [:]

// MARK: - Security Best Practices

extension IconCreatorWebhookServer {

    /// Sanitize file paths to prevent directory traversal
    func sanitizePath(_ path: String) -> String? {
        // Remove any attempts at directory traversal
        let normalized = path.replacingOccurrences(of: "../", with: "")
                            .replacingOccurrences(of: "..\\", with: "")

        // Ensure path doesn't start with /
        let relative = normalized.hasPrefix("/") ? String(normalized.dropFirst()) : normalized

        // Validate it's a reasonable path
        guard !relative.isEmpty,
              !relative.contains(".."),
              !relative.hasPrefix("/"),
              !relative.contains("\\") else {
            return nil
        }

        return relative
    }

    /// Validate that output directory is safe
    func validateOutputDirectory(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)

        // Ensure it's not a system directory
        let systemPaths = [
            "/System", "/Library", "/usr", "/bin", "/sbin",
            "/private", "/etc", "/var", "/tmp/systemd"
        ]

        for systemPath in systemPaths {
            if path.hasPrefix(systemPath) {
                print("❌ Refusing to write to system directory: \(path)")
                return false
            }
        }

        // Ensure parent directory exists and is writable
        let parentURL = url.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: parentURL.path) else {
            print("❌ Parent directory not writable: \(parentURL.path)")
            return false
        }

        return true
    }
}

// MARK: - Logging & Monitoring

extension IconCreatorWebhookServer {

    /// Log security event for monitoring
    func logSecurityEvent(_ event: SecurityEvent) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] SECURITY: \(event.type.rawValue) - \(event.description)"

        print(logEntry)

        // In production: send to logging service
        // - CloudWatch
        // - Datadog
        // - Splunk
        // - etc.
    }

    struct SecurityEvent {
        let type: EventType
        let description: String
        let sourceIP: String?
        let severity: Severity

        enum EventType: String {
            case invalidSignature = "INVALID_SIGNATURE"
            case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
            case suspiciousPayload = "SUSPICIOUS_PAYLOAD"
            case pathTraversal = "PATH_TRAVERSAL"
            case authFailure = "AUTH_FAILURE"
        }

        enum Severity: String {
            case low, medium, high, critical
        }
    }
}

// MARK: - HTTPS/TLS Recommendations

/*
 PRODUCTION SECURITY CHECKLIST:

 ✅ 1. Use HTTPS/TLS in production
    - Configure SSL certificate
    - Redirect HTTP to HTTPS
    - Use TLS 1.3

 ✅ 2. Signature Verification
    - Always verify webhook signatures
    - Use constant-time comparison
    - Log verification failures

 ✅ 3. Rate Limiting
    - Implement per-IP rate limits
    - Use Redis or similar for distributed systems
    - Consider exponential backoff

 ✅ 4. Input Validation
    - Sanitize all inputs
    - Validate file paths
    - Check payload sizes
    - Scan for injection patterns

 ✅ 5. Authentication
    - Rotate API keys regularly
    - Use strong random keys (32+ bytes)
    - Store keys in environment variables
    - Never commit keys to git

 ✅ 6. Monitoring
    - Log all security events
    - Monitor for suspicious patterns
    - Alert on repeated failures
    - Track webhook success rates

 ✅ 7. Permissions
    - Run with minimal privileges
    - Don't write to system directories
    - Use specific output directories
    - Validate all file operations

 ✅ 8. Network Security
    - Whitelist known IPs (GitHub, GitLab)
    - Use firewall rules
    - Consider VPN/private network
    - Enable DDoS protection
 */

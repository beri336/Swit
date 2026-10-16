// src/Swit/CLI/UpdateChecker.swift

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

struct UpdateChecker {
    let manifestURL: URL

    func availableVersion(current: String) async -> String? {
        guard let currentVersion = AppVersion(current) else {
            return nil
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 2
        configuration.timeoutIntervalForResource = 3

        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        var request = URLRequest(url: manifestURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await session.data(for: request)

            guard let http = response as? HTTPURLResponse,
                http.statusCode == 200
            else {
                return nil
            }

            let manifest = try JSONDecoder().decode(
                VersionManifest.self,
                from: data
            )

            guard let remoteVersion = AppVersion(manifest.version),
                remoteVersion > currentVersion
            else {
                return nil
            }

            return manifest.version
        } catch {
            return nil
        }
    }
}

private struct VersionManifest: Decodable {
    let version: String
}

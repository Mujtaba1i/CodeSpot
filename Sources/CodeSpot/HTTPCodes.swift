import Foundation

// HTTP status codes and their one-line descriptions.
// Data from https://github.com/Mujtaba1i/albert-httpstatus (API_v5/__init__.py).

struct Entry: Identifiable, Equatable {
    let code: Int
    let name: String
    let description: String
    var id: Int { code }
}

let httpCodes: [Entry] = [
    Entry(code: 100, name: "Continue", description: "Server received headers, client should send request body"),
    Entry(code: 101, name: "Switching Protocols", description: "Switching protocols as requested"),
    Entry(code: 102, name: "Processing", description: "Processing the request"),
    Entry(code: 103, name: "Early Hints", description: "Returning early response headers"),
    Entry(code: 200, name: "OK", description: "Standard successful HTTP response"),
    Entry(code: 201, name: "Created", description: "New resource created"),
    Entry(code: 202, name: "Accepted", description: "Request accepted for processing"),
    Entry(code: 203, name: "Non-Authoritative Information", description: "Information from another source"),
    Entry(code: 204, name: "No Content", description: "No content returned"),
    Entry(code: 205, name: "Reset Content", description: "Reset document view"),
    Entry(code: 206, name: "Partial Content", description: "Partial resource delivered"),
    Entry(code: 207, name: "Multi-Status", description: "XML with multiple responses"),
    Entry(code: 208, name: "Already Reported", description: "DAV bindings already enumerated"),
    Entry(code: 226, name: "IM Used", description: "GET request fulfilled"),
    Entry(code: 300, name: "Multiple Choices", description: "Multiple resource options"),
    Entry(code: 301, name: "Moved Permanently", description: "Moved permanently"),
    Entry(code: 302, name: "Found", description: "Found at different URI"),
    Entry(code: 303, name: "See Other", description: "See other URI"),
    Entry(code: 304, name: "Not Modified", description: "Not modified since last request"),
    Entry(code: 305, name: "Use Proxy", description: "Use proxy"),
    Entry(code: 306, name: "Switch Proxy (obsolete)", description: "Switch proxy (obsolete)"),
    Entry(code: 307, name: "Temporary Redirect", description: "Temporary redirect"),
    Entry(code: 308, name: "Permanent Redirect", description: "Permanent redirect"),
    Entry(code: 400, name: "Bad Request", description: "Client error in request"),
    Entry(code: 401, name: "Unauthorized", description: "Authentication required"),
    Entry(code: 402, name: "Payment Required", description: "Payment required"),
    Entry(code: 403, name: "Forbidden", description: "Forbidden access"),
    Entry(code: 404, name: "Not Found", description: "Resource not found"),
    Entry(code: 405, name: "Method Not Allowed", description: "Method not allowed"),
    Entry(code: 406, name: "Not Acceptable", description: "Not acceptable"),
    Entry(code: 407, name: "Proxy Authentication Required", description: "Proxy authentication required"),
    Entry(code: 408, name: "Request Timeout", description: "Request timeout"),
    Entry(code: 409, name: "Conflict", description: "Conflict in request"),
    Entry(code: 410, name: "Gone", description: "Resource gone"),
    Entry(code: 411, name: "Length Required", description: "Length required"),
    Entry(code: 412, name: "Precondition Failed", description: "Precondition failed"),
    Entry(code: 413, name: "Payload Too Large", description: "Payload too large"),
    Entry(code: 414, name: "URI Too Long", description: "URI too long"),
    Entry(code: 415, name: "Unsupported Media Type", description: "Unsupported media type"),
    Entry(code: 416, name: "Range Not Satisfiable", description: "Range not satisfiable"),
    Entry(code: 417, name: "Expectation Failed", description: "Expectation failed"),
    Entry(code: 418, name: "I'm a teapot (meme)", description: "I'm a teapot (April Fools joke / meme)"),
    Entry(code: 419, name: "Page Expired (Laravel)", description: "Page expired (Laravel framework)"),
    Entry(code: 420, name: "Enhance Your Calm / Method Failure", description: "Enhance Your Calm / Method Failure (Twitter / meme)"),
    Entry(code: 421, name: "Misdirected Request", description: "Misdirected request"),
    Entry(code: 422, name: "Unprocessable Entity", description: "Unprocessable entity"),
    Entry(code: 423, name: "Locked", description: "Resource locked"),
    Entry(code: 424, name: "Failed Dependency", description: "Failed dependency"),
    Entry(code: 425, name: "Too Early", description: "Too early"),
    Entry(code: 426, name: "Upgrade Required", description: "Upgrade required"),
    Entry(code: 428, name: "Precondition Required", description: "Precondition required"),
    Entry(code: 429, name: "Too Many Requests", description: "Too many requests"),
    Entry(code: 431, name: "Request Header Fields Too Large", description: "Header fields too large"),
    Entry(code: 440, name: "Login Time-out (IIS)", description: "Login timeout (IIS)"),
    Entry(code: 444, name: "No Response (nginx)", description: "No response sent (nginx)"),
    Entry(code: 450, name: "Blocked by Windows Parental Controls", description: "Blocked by Windows Parental Controls"),
    Entry(code: 460, name: "Client Error (vendor)", description: "Client error (vendor specific)"),
    Entry(code: 463, name: "Client Error (vendor)", description: "Client error (vendor specific)"),
    Entry(code: 464, name: "Client Error (vendor)", description: "Client error (vendor specific)"),
    Entry(code: 498, name: "Invalid Token", description: "Invalid token (API)"),
    Entry(code: 499, name: "Client Closed Request", description: "Client closed request (nginx)"),
    Entry(code: 500, name: "Internal Server Error", description: "Internal server error"),
    Entry(code: 501, name: "Not Implemented", description: "Not implemented"),
    Entry(code: 502, name: "Bad Gateway", description: "Bad gateway"),
    Entry(code: 503, name: "Service Unavailable", description: "Service unavailable"),
    Entry(code: 504, name: "Gateway Timeout", description: "Gateway timeout"),
    Entry(code: 505, name: "HTTP Version Not Supported", description: "HTTP version not supported"),
    Entry(code: 506, name: "Variant Also Negotiates", description: "Variant also negotiates"),
    Entry(code: 507, name: "Insufficient Storage", description: "Insufficient storage"),
    Entry(code: 508, name: "Loop Detected", description: "Loop detected"),
    Entry(code: 509, name: "Bandwidth Limit Exceeded", description: "Bandwidth limit exceeded (Apache / cPanel)"),
    Entry(code: 510, name: "Not Extended", description: "Not extended"),
    Entry(code: 511, name: "Network Authentication Required", description: "Network authentication required"),
    Entry(code: 520, name: "Unknown Error (Cloudflare)", description: "Unknown error (Cloudflare)"),
    Entry(code: 521, name: "Web Server Is Down (Cloudflare)", description: "Web server is down (Cloudflare)"),
    Entry(code: 522, name: "Connection Timed Out (Cloudflare)", description: "Connection timed out (Cloudflare)"),
    Entry(code: 523, name: "Origin Is Unreachable (Cloudflare)", description: "Origin is unreachable (Cloudflare)"),
    Entry(code: 524, name: "A Timeout Occurred (Cloudflare)", description: "A timeout occurred (Cloudflare)"),
    Entry(code: 525, name: "SSL Handshake Failed (Cloudflare)", description: "SSL handshake failed (Cloudflare)"),
    Entry(code: 526, name: "Invalid SSL Certificate (Cloudflare)", description: "Invalid SSL certificate (Cloudflare)"),
    Entry(code: 527, name: "Railgun Error (Cloudflare)", description: "Railgun error (Cloudflare)"),
    Entry(code: 530, name: "Site Frozen / DNS Error", description: "Site frozen / DNS error (Shopify / vendor)"),
    Entry(code: 540, name: "Temporarily Disabled", description: "Temporarily disabled (Shopify / vendor)"),
    Entry(code: 598, name: "Network Read Timeout", description: "Network read timeout error"),
    Entry(code: 599, name: "Network Connect Timeout", description: "Network connect timeout error"),
    Entry(code: 783, name: "Unexpected Token (Shopify API)", description: "Unexpected token (Shopify API)"),
]

/// Case-insensitive substring match on code, name or description (same rule as the Albert plugin).
/// Codes starting with the query come first ("5" -> 5xx before 205). An empty query returns every code.
func search(_ query: String) -> [Entry] {
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    if q.isEmpty { return httpCodes }
    let hits = httpCodes.filter {
        String($0.code).contains(q) || $0.name.lowercased().contains(q) || $0.description.lowercased().contains(q)
    }
    let prefixed = hits.filter { String($0.code).hasPrefix(q) }
    return prefixed + hits.filter { !String($0.code).hasPrefix(q) }
}

func runSelfTest() {
    precondition(search("404").first?.code == 404, "404 should match 404 first")
    precondition(search("not found").contains { $0.code == 404 }, "'not found' should include 404")
    precondition(search("Internal Server").contains { $0.code == 500 }, "'internal server' should include 500")
    precondition(search("").count == httpCodes.count, "empty query should return all codes")
    precondition(search("  ").count == httpCodes.count, "blank query should return all codes")
    precondition(search("5").first?.code == 500, "'5' should list 5xx first")
    precondition(search("5").contains { $0.code == 205 }, "'5' should still include 205")
    precondition(search("zzz").isEmpty, "'zzz' should match nothing")
    precondition(httpCodes.map(\.code) == httpCodes.map(\.code).sorted(), "codes should be sorted")
    print("selftest: all \(httpCodes.count) codes OK")
}

import PerfectMiddleware
import PerfectHTTP
import Foundation

/**
 * Blink middleware is a request body, query, params parser
 * Works with JSON, raw, text, urlencoded, form-data body parameters
 */
open class Blink : Middleware {

    /**
     * Retrieve the shared instance of the blink middleware
     */
    public static let shared = Blink()

    /**
     * Info object, this object store all parsed data
     * Retrieves an instance of this class using context.blink method
     */
    public class Info {
        /** The parsed body */
        public fileprivate(set) var body: Any?
        /** The parsed query as key/value */
        public fileprivate(set) var query: [String: String]?
        /** The parsed url params as key/value */
        public fileprivate(set) var params: [String: String]?
    }

    /**
     * Blink consts
     */
    public enum Consts {
        /** Retrieves the key for the Info object inside the route context */
        public static let infoKey = "blink_info"
    }

    /**
     * This class cannot be instanciate
     */
    private init() {
    }

    /**
     * Try to find the correct parser, after that parse input request and store the result
     * inside the Info object in the route context
     * @param context The route context
     */
    public func handle(context: RouteContext) throws {
        let blink = context.blink
        let request = context.request
        if blink.query == nil {
            blink.query = Blink.queryParams(from: request)
        }
        if blink.params == nil {
            blink.params = Blink.urlParams(from: request)
        }
        if blink.body == nil {
            guard let contentType = context.request.header(.contentType) else {
                return context.next()
            }
            if contentType == "application/json" {
                blink.body = try Blink.json(from: context.request)
            } else if contentType == "application/x-www-form-urlencoded" {
                blink.body = Blink.bodyParams(from: context.request)
            } else if contentType == "multipart/form-data" {
                blink.body = Blink.bodyParams(from: context.request)
            } else if contentType.characters.starts(with: "text".characters) {
                blink.body = Blink.text(from: context.request)
            } else {
                blink.body = Blink.data(from: context.request)
            }
        }
        context.next()
    }

    /**
     * Parse only json body request inside the Info object in the route context
     */
    public func json() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.body == nil else {
                return context.next()
            }
            blink.body = try Blink.json(from: context.request)
            context.next()
        }
    }

    /**
     * Parse only urlEncoded body request inside the Info object in the route context
     */
    public func urlEncoded() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.body == nil else {
                return context.next()
            }
            blink.body = Blink.bodyParams(from: context.request)
            context.next()
        }
    }

    /**
     * Parse only multipart body request inside the Info object in the route context
     * This method will retrieve only parameters, files will be ignored
     */
    public func multiPart() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.body == nil else {
                return context.next()
            }
            blink.body = Blink.bodyParams(from: context.request)
            context.next()
        }
    }

    /**
     * Parse only UTF-8 string request inside the Info object in the route context
     */
    public func text() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.body == nil else {
                return context.next()
            }
            blink.body = Blink.text(from: context.request)
            context.next()
        }
    }

    /**
     * Parse the body request as data inside the Info object in the route context
     */
    public func data() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.body == nil else {
                return context.next()
            }
            blink.body = Blink.data(from: context.request)
            context.next()
        }
    }

    /**
     * Retrieve and save query parameters as key / value inside the Info object in the route context
     */
    public func query() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.query == nil else {
                return context.next()
            }
            blink.query = Blink.queryParams(from: context.request)
            context.next()
        }
    }

    /**
     * Retrieve and save url parameters as key / value inside the Info object in the route context
     */
    public func params() -> MiddlewareHandler {
        return { (context: RouteContext) in
            let blink = context.blink
            guard blink.params == nil else {
                return context.next()
            }
            blink.params = Blink.urlParams(from: context.request)
            context.next()
        }
    }
}

/**
 * Add Blink support to the route context
 */
public extension RouteContext {

    /**
     * Access to data stored by Blink (Info object)
     */
    public var blink: Blink.Info {
        if let info = self[Blink.Consts.infoKey] as? Blink.Info {
            return info
        }
        let info = Blink.Info()
        self[Blink.Consts.infoKey] = info
        return info
    }
}

fileprivate extension Blink {

    fileprivate static func text(from request: HTTPRequest) -> String? {
        return request.postBodyString
    }

    fileprivate static func data(from request: HTTPRequest) -> Data? {
        guard let bytes = request.postBodyBytes else {
            return nil
        }
        return Data(bytes: bytes)
    }

    fileprivate static func json(from request: HTTPRequest) throws -> Any? {
        guard let data = Blink.data(from: request) else {
            return nil
        }
        return try JSONSerialization.jsonObject(with: data)
    }

    fileprivate static func bodyParams(from request: HTTPRequest) -> [String: String] {
        var body = [String: String]()
        request.postParams.forEach({ (key, value) in
            body[key] = value
        })
        return body
    }

    fileprivate static func queryParams(from request: HTTPRequest) -> [String: String] {
        var query = [String: String]()
        request.queryParams.forEach({ (key, value) in
            query[key] = value
        })
        return query
    }

    fileprivate static func urlParams(from request: HTTPRequest) -> [String: String] {
        var params = [String: String]()
        request.urlVariables.forEach({ (key, value) in
            params[key] = value
        })
        return params
    }
}

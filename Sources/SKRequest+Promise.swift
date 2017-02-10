import PromiseKit
import StoreKit

/**
 To import the `SKRequest` category:

    use_frameworks!
    swift_version = "3.0"
    pod "PromiseKit/StoreKit"

 And then in your sources:

    import PromiseKit
*/
extension SKRequest {
    /**
     Sends the request to the Apple App Store.

     - Returns: A promise that fulfills if the request succeeds.
    */
    public func start(_: PMKNamespacer) -> Promise<SKProductsResponse> {
        let proxy = SKDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        start()
        return proxy.promise
    }
}


private class SKDelegate: NSObject, SKProductsRequestDelegate {
    let (promise, seal) = Promise<SKProductsResponse>.pending()
    var retainCycle: SKDelegate?

    @objc func request(_ request: SKRequest, didFailWithError error: Error) {
        let nsError = error as NSError
        if nsError.domain == SKErrorDomain, nsError.code == SKError.Code.paymentCancelled.rawValue {
            seal.reject(PMKError.cancelled)
        } else {
            seal.reject(error)
        }
        retainCycle = nil
    }

    @objc func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        seal.fulfill(response)
        retainCycle = nil
    }
}

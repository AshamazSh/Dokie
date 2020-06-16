//
//  AES.swift
//  Dokie
//
//  Created by Ashamaz Shidov on 31.05.2020.
//  Copyright © 2020 Ashamaz Shidov. All rights reserved.
//

import UIKit
import CommonCrypto

struct AESSwift {
    
    let key: String
    private let encryptionKey: Data
    
    init(key: String) {
        self.key = key
        self.encryptionKey = key.aes256Key()!
    }
    
    func encrypt(_ data: Data) -> Data? {
        return crypt(data: data, option: CCOperation(kCCEncrypt))
    }
    
    func decrypt(_ data: Data) -> Data? {
        return crypt(data: data, option: CCOperation(kCCDecrypt))
    }
    
    private func crypt(data: Data, option: CCOperation) -> Data? {
        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData   = Data(count: cryptLength)
        
        let keyLength = encryptionKey.count
        let options   = CCOptions(kCCOptionPKCS7Padding)
        
        var bytesLength = Int(0)
        
        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                encryptionKey.withUnsafeBytes { keyBytes in
                    CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, keyBytes.baseAddress, keyLength, nil, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
                }
            }
        }
        
        guard Int(status) == Int(kCCSuccess) else {
            debugPrint("Error: Failed to crypt data. Status \(status)")
            return nil
        }
        
        cryptData.removeSubrange(bytesLength..<cryptData.count)
        return cryptData
    }
    
}

extension String {
    
    func aes256Key() -> Data? {
        return padding(toLength: kCCKeySizeAES256, withPad: "0", startingAt: 0).data(using: .utf8)
    }
    
}

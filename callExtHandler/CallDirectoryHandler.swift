//
//  CallDirectoryHandler.swift
//  callExtHandler
//
//  Created by 김기웅 on 2021/06/18.
//

import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // Check whether this is an "incremental" data request. If so, only provide the set of phone number blocking
        // and identification entries which have been added or removed since the last time this extension's data was loaded.
        // But the extension must still be prepared to provide the full set of data at any time, so add all blocking
        // and identification phone numbers if the request is not incremental.
        /*
        if context.isIncremental {
            addOrRemoveIncrementalBlockingPhoneNumbers(to: context)

            addOrRemoveIncrementalIdentificationPhoneNumbers(to: context)
        } else {
            addAllBlockingPhoneNumbers(to: context)

            addAllIdentificationPhoneNumbers(to: context)
        }*/
        do {
             try addIdentificationPhoneNumbers(to: context)
        } catch {
            NSLog("Unable to add identification phone numbers")
            let error = NSError(domain: "CallDirectoryHandler", code: 2, userInfo: nil)
            context.cancelRequest(withError: error)
            return
        }

        context.completeRequest()
    }

    private func addIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) throws {
/*
        let phoneNumbers: [CXCallDirectoryPhoneNumber] = [ 821027463270, 8201027463270]

        let labels = [ "인포 시스템운영실 팀장 김김김", "서울 다산콜센터" ]

        for (phoneNumber, label) in zip(phoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
            //labelsKeyedByPhoneNumber[CXCallDirectoryPhoneNumber.init(phoneNumber)!] = "1234567890"
        }
*/

        //let userDefaults = UserDefaults(suiteName: "group.com.team_call.callkit")
        let userDefaults = UserDefaults(suiteName: "group.teamcall.teamcall")
        
        var labelsKeyedByPhoneNumber: [CXCallDirectoryPhoneNumber: String] = [ : ]

        //UserData는 보내는 부분과 받는 부분에 둘다 생성해줘야하는 문제가 있습니다.
        //프레임워크로 설정을 하는 방식 또는 이번 샘플 소스처럼 두개를 만들어서 관리해야하는 방식 두가지로 나눠집니다.
        if let data = userDefaults?.object(forKey:"dbData") as? Data {
            if let userData = try? PropertyListDecoder().decode([UserData].self, from: data) {
                for data in userData {
                    //실직적인 데이터를 넣어주는 부분
                    labelsKeyedByPhoneNumber[CXCallDirectoryPhoneNumber.init(data.phoneNumber)!] = data.name
                }
            }
        }
        //3개 이상으로 구성된 것은 다음과 같은 방식으로 sort 하여 설정합니다.
        for (phoneNumber, label) in labelsKeyedByPhoneNumber.sorted(by: <) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }

    
    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve all phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let allPhoneNumbers: [CXCallDirectoryPhoneNumber] = [ 1_408_555_5555, 1_800_555_5555 ]
        for phoneNumber in allPhoneNumbers {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }
    }

    private func addOrRemoveIncrementalBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve any changes to the set of phone numbers to block from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        let phoneNumbersToAdd: [CXCallDirectoryPhoneNumber] = [ 1_408_555_1234 ]
        for phoneNumber in phoneNumbersToAdd {
            context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
        }

        let phoneNumbersToRemove: [CXCallDirectoryPhoneNumber] = [ 1_800_555_5555 ]
        for phoneNumber in phoneNumbersToRemove {
            context.removeBlockingEntry(withPhoneNumber: phoneNumber)
        }

        // Record the most-recently loaded set of blocking entries in data store for the next incremental load...
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve phone numbers to identify and their identification labels from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        //
        // Numbers must be provided in numerically ascending order.
        let allPhoneNumbers: [CXCallDirectoryPhoneNumber] = [ 1_877_555_5555, 1_888_555_5555 ]
        let labels = [ "Telemarketer", "Local business" ]

        for (phoneNumber, label) in zip(allPhoneNumbers, labels) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }
    }

    private func addOrRemoveIncrementalIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        // Retrieve any changes to the set of phone numbers to identify (and their identification labels) from data store. For optimal performance and memory usage when there are many phone numbers,
        // consider only loading a subset of numbers at a given time and using autorelease pool(s) to release objects allocated during each batch of numbers which are loaded.
        let phoneNumbersToAdd: [CXCallDirectoryPhoneNumber] = [ 1_408_555_5678 ]
        let labelsToAdd = [ "New local business" ]

        for (phoneNumber, label) in zip(phoneNumbersToAdd, labelsToAdd) {
            context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
        }

        let phoneNumbersToRemove: [CXCallDirectoryPhoneNumber] = [ 1_888_555_5555 ]

        for phoneNumber in phoneNumbersToRemove {
            context.removeIdentificationEntry(withPhoneNumber: phoneNumber)
        }

        // Record the most-recently loaded set of identification entries in data store for the next incremental load...
    }

}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {

    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // An error occurred while adding blocking or identification entries, check the NSError for details.
        // For Call Directory error codes, see the CXErrorCodeCallDirectoryManagerError enum in <CallKit/CXError.h>.
        //
        // This may be used to store the error details in a location accessible by the extension's containing app, so that the
        // app may be notified about errors which occurred while loading data even if the request to load data was initiated by
        // the user in Settings instead of via the app itself.
    }

}

// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/test;
import ballerina/lang.runtime;
import ballerinax/sfdc;

json testCaseRecord = {
    Status: "New",
    Origin: "Phone"
};
string testCaseId = "";
string testCaseNumber = "";
string testSpreadsheetId = "";

@test:Config {}
function testNewCaseRecord() {
    log:print("sfdcClient -> createRecord()");
    string|sfdc:Error stringResponse = sfdcClient->createRecord("Case", testCaseRecord);
    if (stringResponse is string) {
        test:assertNotEquals(stringResponse, "", msg = "Found empty response!");
        testCaseId = <@untainted>stringResponse;
    } else {
        test:assertFail(msg = stringResponse.message());
    }
    runtime:sleep(12);
}

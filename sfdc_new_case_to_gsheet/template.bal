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

import ballerinax/googleapis_sheets as sheets4;
import ballerina/io;
import ballerina/log;
import ballerina/os;
import ballerinax/sfdc;

configurable string sfBaseUrl =  os:getEnv("SF_EP_URL");
configurable string sfClientId =  os:getEnv("SF_CLIENT_ID");
configurable string sfClientSecret = os:getEnv("SF_CLIENT_SECRET");
configurable string sfRefreshToken = os:getEnv("SF_REFRESH_TOKEN");
configurable string sfRefreshUrl = os:getEnv("SF_REFRESH_URL");

configurable string gSheetClientId =  os:getEnv("GS_CLIENT_ID");
configurable string gSheetClientSecret = os:getEnv("GS_CLIENT_SECRET");
configurable string gSheetRefreshToken = os:getEnv("GS_REFRESH_TOKEN");

configurable string sfUsername =  os:getEnv("SF_USERNAME");
configurable string sfPassword = os:getEnv("SF_PASSWORD");

configurable string sfTopic =  os:getEnv("SF_CASE_TOPIC");

sfdc:SalesforceConfiguration sfConfig = {
    baseUrl: sfBaseUrl,
    clientConfig: {
        clientId: sfClientId,
        clientSecret: sfClientSecret,
        refreshToken: sfRefreshToken,
        refreshUrl: sfRefreshUrl
    }
};

sheets4:SpreadsheetConfiguration spreadsheetConfig = {
    oauthClientConfig: {
        refreshUrl: sheets4:REFRESH_URL,
        refreshToken: gSheetRefreshToken,
        clientId: gSheetClientId,
        clientSecret: gSheetClientSecret
    }
};

sfdc:ListenerConfiguration listenerConfig = {
    username: sfUsername,
    password: sfPassword
};

listener sfdc:Listener sfdcEventListener = new (listenerConfig);
sfdc:BaseClient sfdcClient = checkpanic new (sfConfig);
sheets4:Client gSheetClient = checkpanic new (spreadsheetConfig);

@sfdc:ServiceConfig {topic: sfTopic}
service on sfdcEventListener {
    remote function onEvent(json case) {
        io:StringReader sr = new (case.toJsonString());
        json|error caseInfo = sr.readJson();
        if (caseInfo is json) {
            json|error eventType = caseInfo.event.'type;
            if (eventType is json) {
                if(CREATED.equalsIgnoreCaseAscii(eventType.toString())){
                    json|error caseId = caseInfo.sobject.Id;
                    json|error caseRecord = "";
                    if (caseId is json) {
                        caseRecord = sfdcClient->getRecordById("Case", caseId.toString());
                        log:print("Case ID = " + caseId.toString());
                    }
                    if (caseRecord is json) {
                        [string,string]|error response = createSheetWithNewCase(caseRecord);
                        if (response is [string, string]) {
                            log:print("Spreadsheet with ID "+response[0] + " is created for new Salesforce Case Number "
                                + response[1]); 
                        } else {                       
                            log:printError(response.toString());
                        }
                    }
                    else {
                        log:printError(caseRecord.toString());
                    }
                }  
            } else {
                log:printError(eventType.message());
            }    
        }
        else
        {
            log:printError(caseInfo.toString());
        }
    }
}

function createSheetWithNewCase(json case) returns @tainted [string,string] | error {
    json|error caseNumberValue = case.CaseNumber;
    if (caseNumberValue is json ) {
        string caseNumber =  caseNumberValue.toString();
        sheets4:Spreadsheet spreadsheet = check gSheetClient->createSpreadsheet("Salesforce Case " + caseNumber);
        string spreadsheetId = spreadsheet.spreadsheetId;
        sheets4:Sheet sheet = check gSheetClient->getSheetByName(spreadsheetId, "Sheet1");
        map<json> caseMap = <map<json>> case;
        foreach var [key, value] in caseMap.entries() {
            var response = gSheetClient->appendRowToSheet(spreadsheetId, sheet.properties.title, [key, value.toString()]);
            if(response is error){
                log:printError(response.message());
            }
        } 
        return [spreadsheetId, caseNumber];
    } else {
        return caseNumberValue;
    }
    
}

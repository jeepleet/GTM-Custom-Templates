___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "pLTV Tag",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "apiBaseUrl",
    "displayName": "Enter URL of Render App",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "getCustomerIdFrom",
    "displayName": "Specifies where to find the customer_id",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "eventTypesToPredict",
    "displayName": "A comma-separated list of event names the tag should request a pLTV prediction.",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "stapeStoreDocumentId",
    "displayName": "Enter Document ID for Stape Store",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "stapeStoreBaseUrl",
    "displayName": "Enter Your Stape Store URL here",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "stapeApiKey",
    "displayName": "Enter Stape Store API Key here",
    "simpleValueType": true
  },
  {
    "type": "CHECKBOX",
    "name": "predictPltv",
    "checkboxText": "If checked, the tag will attempt to get a pLTV prediction from your /predict endpoint",
    "simpleValueType": true
  },
  {
    "type": "CHECKBOX",
    "name": "sendEventData",
    "checkboxText": "Check this box if you want the tag to send the incoming GA4 event data",
    "simpleValueType": true
  }
]


___SANDBOXED_JS_FOR_SERVER___

// Import necessary sGTM APIs
const sendHttpRequest = require('sendHttpRequest');
const getEventData = require('getEventData');
const getAllEventData = require('getAllEventData');
const logToConsole = require('logToConsole');
const JSON = require('JSON');
const Promise = require('Promise');
const getType = require('getType');
const makeString = require('makeString');
const encodeUriComponent = require('encodeUriComponent');

// Input parameters
var apiBaseUrl = data.apiBaseUrl;
var sendEventData = data.sendEventData;
var getCustomerIdFrom = data.getCustomerIdFrom;
var predictPltv = data.predictPltv;
var stapeStoreBaseUrl = data.stapeStoreBaseUrl;
var stapeApiKey = data.stapeApiKey;

var eventTypesToPredict = [];
if (data.eventTypesToPredict) {
  if (getType(data.eventTypesToPredict) === 'string') {
    eventTypesToPredict = data.eventTypesToPredict.split(',').map(function(s) { return s.trim(); });
  } else if (getType(data.eventTypesToPredict) === 'array') {
    eventTypesToPredict = data.eventTypesToPredict.map(function(s) { return makeString(s).trim(); });
  }
}

// --- Helper: array includes ---
function arrayIncludes(array, value) {
  for (var i = 0; i < array.length; i++) {
    if (array[i] === value) return true;
  }
  return false;
}

// --- Helper: get customer ID ---
function getCustomerId() {
  var customerId = data.getCustomerIdFrom;
  if (customerId && typeof customerId === 'string' && customerId.trim() !== '') {
    return customerId;
  }
  return undefined;
}

// --- Main Tag Logic ---
return Promise.create(function(resolve, reject) {
  var customerId = getCustomerId();
  if (!customerId) {
    logToConsole('pLTV Tag: No customer ID found. Skipping.');
    return resolve();
  }

  var currentEventName = getEventData('event_name');
  var promises = [];

  // --- Action 1: Send event data to /event endpoint ---
  if (sendEventData) {
    var eventPayload = {
      customer_id: customerId,
      event_data: {
        events: [getAllEventData()]
      }
    };
    var sendEventPromise = sendHttpRequest(apiBaseUrl + '/event', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      timeout: 20000
    }, JSON.stringify(eventPayload))
    .then(function(response) {
      if (response.statusCode === 200) {
        logToConsole('pLTV Tag: Event sent successfully to /event.');
      } else {
        logToConsole('pLTV Tag: Error sending event to /event. Status:', response.statusCode, 'Body:', response.body);
      }
    })
    .catch(function(error) {
      logToConsole('pLTV Tag: Network error sending event to /event:', error);
    });
    promises.push(sendEventPromise);
  }

  // --- Action 2: Retrieve pLTV from /predict endpoint ---
  if (predictPltv && arrayIncludes(eventTypesToPredict, currentEventName)) {
    var predictPayload = { customer_id: customerId };

    logToConsole('pLTV Tag: Requesting pLTV prediction for customer:', customerId);

    var predictPromise = sendHttpRequest(apiBaseUrl + '/predict', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      timeout: 20000
    }, JSON.stringify(predictPayload))
    .then(function(response) {
      if (response.statusCode === 200) {
        var responseBody = JSON.parse(response.body);
        var pltv = responseBody && responseBody.pltv;
        if (typeof pltv === 'number') {
          logToConsole('pLTV Tag: Received pLTV:', pltv, 'for customer:', customerId);

          // --- ✅ STAPE STORE SECTION (FIXED) ---
          var documentId = data.stapeStoreDocumentId;
          var encodedDocumentId = encodeUriComponent(documentId);

          // ✅ CORRECT: Construct URL with API key in path and document ID at end
          var postUrl =
            (stapeStoreBaseUrl.indexOf('https://') === 0
              ? stapeStoreBaseUrl
              : 'https://' + stapeStoreBaseUrl) +
            '/stape-api/' + stapeApiKey + '/v2/store/collections/pltv/documents/' + encodedDocumentId;

          // ✅ CORRECT: Send data directly without "document" wrapper
          var postPayload = JSON.stringify({ "pltv": pltv });

          logToConsole(
            'pLTV Tag Debug:\n' +
            '  - Base URL: ' + stapeStoreBaseUrl + '\n' +
            '  - API Key Length: ' + (stapeApiKey ? stapeApiKey.length : 'undefined') + '\n' +
            '  - Customer ID: ' + customerId + '\n' +
            '  - Document ID: ' + documentId + '\n' +
            '  - Encoded Document ID: ' + encodedDocumentId + '\n' +
            '  - Final URL: ' + postUrl + '\n' +
            '  - Payload: ' + postPayload
          );

          var storePromise = sendHttpRequest(postUrl, {
            method: 'PUT',  // ✅ Use PUT for upsert (creates or updates)
            headers: {
              'Content-Type': 'application/json'
            },
            timeout: 5000
          }, postPayload)
          .then(function(stapeResponse) {
            if (stapeResponse.statusCode >= 200 && stapeResponse.statusCode < 300) {
              logToConsole('pLTV Tag: Stored pLTV in Stape Store successfully (PUT upsert).');
            } else {
              logToConsole('pLTV Tag: Error storing pLTV in Stape Store. Status:', stapeResponse.statusCode, 'Body:', stapeResponse.body);
            }
          })
          .catch(function(stapeError) {
            logToConsole('pLTV Tag: Network error storing pLTV in Stape Store:', stapeError);
          });
          // --- ✅ END STAPE STORE SECTION ---

          return storePromise.then(function() {
            return { pltv_value: pltv };
          });
        }
      }
      logToConsole('pLTV Tag: Did not receive a valid pLTV value.');
      return {};
    })
    .catch(function(error) {
      logToConsole('pLTV Tag: Network error getting pLTV:', error);
      return {};
    });
    promises.push(predictPromise);
  }

  // Wait for all async work
  Promise.all(promises)
    .then(function(results) {
      var dataToAugment = {};
      for (var i = 0; i < results.length; i++) {
        var result = results[i];
        if (result && result.pltv_value) {
          dataToAugment.pltv_value = result.pltv_value;
        }
      }
      data.gtmOnSuccess(dataToAugment);
      resolve();
    })
    .catch(function(error) {
      logToConsole('pLTV Tag: One of the promises failed:', error);
      data.gtmOnFailure();
      reject();
    });
});


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 11/7/2025, 2:39:29 PM



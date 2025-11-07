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
  "displayName": "DataLayer Capture",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Tag that captures the dataLayer on a specific or multiple events. Made by Jeppe S. Nielsen",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "captureEvent",
    "displayName": "Enter the specific events that should be captured.",
    "simpleValueType": true,
    "help": "This could be view_item or purchase event.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// Require the necessary APIs
const copyFromWindow = require('copyFromWindow');
const createQueue = require('createQueue');
const logToConsole = require('logToConsole');
const JSON = require('JSON');

// Create a function that can push to the dataLayer
const dataLayerPush = createQueue('dataLayer');

// Get the specific event name to capture from the template's 'captureEvent' field
const eventToCapture = data.captureEvent;

// Exit if no event name is provided in the tag settings
if (!eventToCapture) {
  logToConsole('GTM DataLayer Logger: No event name specified in the "captureEvent" field. Tag will not run.');
  data.gtmOnFailure();
  return;
}

// Get a copy of the entire dataLayer from the window
const dataLayer = copyFromWindow('dataLayer');

if (dataLayer && dataLayer.length) {
  let eventObject = null;

  // The object from copyFromWindow is not a true JS array, so we can't use methods like .slice() or .find().
  // We must iterate over it with a classic for loop.
  // We loop backwards from the end of the array to find the most recent matching event.
  for (let i = dataLayer.length - 1; i >= 0; i--) {
    if (dataLayer[i] && dataLayer[i].event === eventToCapture) {
      eventObject = dataLayer[i];
      break; // Stop after finding the most recent one
    }
  }

  if (eventObject) {
    // If the event is found, push a new event containing only the data for that specific event.
    dataLayerPush({
      'event': 'dataLayerCaptured',
      'capturedEventName': eventToCapture,
      'capturedEventData': JSON.stringify(eventObject)
    });
    data.gtmOnSuccess();
  } else {
    // If the specified event is not found, log it and signal failure.
    logToConsole('GTM DataLayer Logger: Event "' + eventToCapture + '" not found in dataLayer at time of capture.');
    data.gtmOnFailure();
  }
} else {
  // If the dataLayer object doesn't exist or is empty.
  logToConsole('GTM DataLayer Logger: The dataLayer object was not found on the window or was empty.');
  data.gtmOnFailure();
}


___WEB_PERMISSIONS___

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
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "dataLayer"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
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

Created on 11/7/2025, 2:42:59 PM



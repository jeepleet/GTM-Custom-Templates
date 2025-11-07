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
  "displayName": "Cart Token Datalayer Pusher",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "splitString",
    "displayName": "Split the cart token string if you wish.",
    "simpleValueType": true,
    "help": "Example split at %."
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const getCookieValues = require('getCookieValues');
const callInWindow = require('callInWindow');
const logToConsole = require('logToConsole');

const values = getCookieValues ? getCookieValues('cart', true) : [];
const cartCookie = values && values.length ? values[0] : '';

// Optional split based on template field `splitString` (defaults to no split)
const splitStringInput = data && typeof data.splitString === 'string' ? data.splitString : '';
const splitString = splitStringInput ? splitStringInput.trim() : '';
let cartToken = cartCookie;
if (splitString) {
  const idx = (cartCookie || '').indexOf(splitString);
  // Debug to help verify template field and split position in preview
  if (logToConsole) {
    logToConsole('carttoken_datalayer_push: splitString', splitString, 'index', idx);
  }
  if (idx !== -1) {
    cartToken = (cartCookie || '').slice(0, idx);
  }
}

// Push event to dataLayer if possible
if (callInWindow) {
  callInWindow('dataLayer.push', {
    event: 'cart',
    cart: cartToken,
  });
  data.gtmOnSuccess();
} else {
  logToConsole('carttoken_datalayer_push: callInWindow not available');
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
    "clientAnnotations": {
      "isEditedByUser": true
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
                    "string": "dataLayer.push"
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
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
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

Created on 11/7/2025, 2:41:03 PM



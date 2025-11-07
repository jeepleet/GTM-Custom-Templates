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
  "displayName": "DataLayer Push - Custom PageView for SPA",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "Datalayer push for custom page_view event for SPA tracking. Made by Jeppe S. Nielsen :)",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// spatag.js — Web GTM Custom Template (ES5, SPA-safe, title-stabilized)
// No fields, no consent

var createQueue         = require('createQueue');
var getUrl              = require('getUrl');
var getReferrerUrl      = require('getReferrerUrl');
var readTitle           = require('readTitle');
var getType             = require('getType');
var templateStorage     = require('templateStorage');
var callLater           = require('callLater');
var getTimestampMillis  = require('getTimestampMillis');
var Math                = require('Math').Math;
var isConsentGranted    = require('isConsentGranted');
var addConsentListener  = require('addConsentListener');

var dlPush = createQueue('dataLayer');

var currentUrl = getUrl() || '';

var prevUrl = templateStorage.getItem('prevUrl');
if (getType(prevUrl) !== 'string') { prevUrl = ''; }

var previousTitle = templateStorage.getItem('lastTitle');
if (getType(previousTitle) !== 'string') { previousTitle = ''; }

// Bound waiting by eventTimeout (headroom 100ms). No Date(), use GTM timer APIs.
var maxWaitMs = 800;
if (data && typeof data.eventTimeout === 'number' && data.eventTimeout > 100) {
  maxWaitMs = Math.max(0, data.eventTimeout - 100);
}
var startTs = getTimestampMillis();
var lastConsentChangeTimestamp = 0;

var consentChangeQueued = false;
function processConsentChange() {
  var now = getTimestampMillis();
  // Only process if enough time has passed since the last actual processing
  // This acts as a debounce for a short period (e.g., 50ms)
  if (now - lastConsentChangeTimestamp > 50) { // 50ms debounce window
    lastConsentChangeTimestamp = now;
    triggerPageView(readTitle() || '');
  }
  consentChangeQueued = false; // Reset flag after processing or if debounced
}

function triggerPageView(title) {
  dlPush({
    event: 'page_view_ce',
    pageUrl: currentUrl,
    pagetitle: title,
    previousurl: prevUrl,
    referrer: getReferrerUrl() || '',
    ad_storage: isConsentGranted('ad_storage'),
    analytics_storage: isConsentGranted('analytics_storage')
  });

  // persist for next navigation
  templateStorage.setItem('prevUrl', currentUrl);
  templateStorage.setItem('lastTitle', title);

  if (data && typeof data.gtmOnSuccess === 'function') { data.gtmOnSuccess(); }
}

// poll for updated <title> (SPA often updates after History Change)
function settleTitle() {
  var t = readTitle();
  if (getType(t) !== 'string') { t = ''; }

  var titleLooksNew = !!t && (!previousTitle || t !== previousTitle);
  var timedOut = (getTimestampMillis() - startTs) >= maxWaitMs;

  if (titleLooksNew || timedOut) {
    // push event
    triggerPageView(t);
  } else {
    // yield to the SPA, try again next tick
    callLater(settleTitle);
  }
}

settleTitle();

addConsentListener('ad_storage', function(consentType, granted) {
  if (!consentChangeQueued) {
    consentChangeQueued = true;
    callLater(processConsentChange);
  }
});
addConsentListener('analytics_storage', function(consentType, granted) {
  if (!consentChangeQueued) {
    consentChangeQueued = true;
    callLater(processConsentChange);
  }
});


___WEB_PERMISSIONS___

[
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
  },
  {
    "instance": {
      "key": {
        "publicId": "read_title",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
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
        "publicId": "get_referrer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_storage"
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
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "analytics_storage"
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

Created on 11/7/2025, 2:44:40 PM



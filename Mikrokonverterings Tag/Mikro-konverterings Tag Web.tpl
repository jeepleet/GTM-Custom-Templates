___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Mikro-konverterings Tag",
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
    "type": "SIMPLE_TABLE",
    "name": "eventScoringTable",
    "displayName": "Event Scoring Table",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Event Name",
        "name": "event_name",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Event Score",
        "name": "event_score",
        "type": "TEXT"
      }
    ],
    "help": "Map event names to their score values."
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "goalThresholdsTable",
    "displayName": "Goal Thresholds Table",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Goal Name",
        "name": "goal_name",
        "type": "TEXT"
      },
      {
        "defaultValue": "",
        "displayName": "Goal Threshold",
        "name": "goal_threshold",
        "type": "TEXT"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "currentEvent",
    "displayName": "Current Event Name",
    "simpleValueType": true,
    "help": "The event name to score for this tag execution."
  },
  {
    "type": "PARAM_TABLE",
    "name": "paramTable1",
    "displayName": "",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "cookieName",
          "displayName": "Set the name of your cookie",
          "simpleValueType": true,
          "valueValidators": [
            {
              "type": "NON_EMPTY"
            }
          ]
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "TEXT",
          "name": "cookieExpirationDays",
          "displayName": "Cookie expiration",
          "simpleValueType": true,
          "valueValidators": [
            {
              "type": "NON_EMPTY"
            }
          ]
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "TEXT",
          "name": "cookieDomain",
          "displayName": "Domain",
          "simpleValueType": true,
          "defaultValue": "auto"
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "SELECT",
          "name": "cookieSameSite",
          "displayName": "SameSite",
          "macrosInSelect": true,
          "selectItems": [
            {
              "value": "lax",
              "displayValue": "lax"
            },
            {
              "value": "strict",
              "displayValue": "strict"
            },
            {
              "value": "none",
              "displayValue": "none"
            }
          ],
          "simpleValueType": true
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "CHECKBOX",
          "name": "cookieEncodeValue",
          "checkboxText": "Encode cookie",
          "simpleValueType": true
        },
        "isUnique": false
      }
    ],
    "newRowButtonText": "Cookie Settings"
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// GTM Web Custom Tag Template: Visitor Event Lead Scoring
// (direct data.* mapping, no-consent, no-localStorage, ES5)

// -----------------------------------------------------------------------------
// Sandboxed APIs (enable in Template > Permissions)
// -----------------------------------------------------------------------------
var getCookieValues   = require('getCookieValues');
var setCookie         = require('setCookie');
var logToConsole      = require('logToConsole');
var makeTableMap      = require('makeTableMap');
var makeInteger       = require('makeInteger');
var makeString        = require('makeString');
var createQueue       = require('createQueue');
var copyFromDataLayer = require('copyFromDataLayer');

// -----------------------------------------------------------------------------
// Template fields (ALL read from data.*)
// -----------------------------------------------------------------------------
var eventScoringTable   = data.eventScoringTable || [];   // [{event_name, event_score}]
var goalThresholdsTable = data.goalThresholdsTable || []; // [{goal_name, goal_threshold}]
var currentEvent        = data.currentEvent || '';        // literal or wildcard pattern

// Cookie fields mapped like other template fields
var cookieName            = data.cookieName || '';
var cookieExpirationDays  = data.cookieExpirationDays || 0;
var cookieDomain          = data.cookieDomain || '';
var cookieSameSite        = data.cookieSameSite || '';
var cookieEncodeValue     = data.cookieEncodeValue || false;

// Derived helpers
var cookieDaysRv = makeInteger(cookieExpirationDays);

// If a cookie settings SIMPLE_TABLE is used, prefer its first row. Support 'paramTable1'.
var __cookieTable = data.paramTable1 || data.cookieConfigTable || data.cookieSettingsTable || data.cookieTable || [];
if (__cookieTable && __cookieTable.length > 0) {
  var __row = __cookieTable[0];
  if (__row.cookieName !== undefined) cookieName = __row.cookieName;
  if (__row.cookieExpirationDays !== undefined) {
    cookieExpirationDays = __row.cookieExpirationDays;
    cookieDaysRv = makeInteger(cookieExpirationDays);
  }
  if (__row.cookieDomain !== undefined) cookieDomain = __row.cookieDomain;
  if (__row.cookieSameSite !== undefined) cookieSameSite = __row.cookieSameSite;
  if (__row.cookieEncodeValue !== undefined) {
    cookieEncodeValue = (__row.cookieEncodeValue === true) || (makeString(__row.cookieEncodeValue) === 'true');
  }
}
var debug = (makeString(data.debug) === 'true') || (data.debug === true);

// Validate cookie name
if (!cookieName || makeString(cookieName) === '') {
  logToConsole('ERROR: Cookie name is empty!');
  data.gtmOnFailure();
  return;
}

// -----------------------------------------------------------------------------
// Helpers (no RegExp/Date/Math/try-catch)
// -----------------------------------------------------------------------------

// Simple wildcard matcher (supports '*', case-insensitive).
// Also accepts '/patt/flags' by stripping slashes and treating as wildcard text.
function matchesPattern(text, pattern) {
  var t = makeString(text).toLowerCase();
  var p = makeString(pattern);
  if (!p) return false;

  if (p.length >= 2 && p.charAt(0) === '/' && p.lastIndexOf('/') > 0) {
    p = p.substring(1, p.lastIndexOf('/')); // ignore flags
  }
  p = p.toLowerCase();

  if (t === p) return true;               // exact
  if (p.indexOf('*') === -1) return false;

  // Greedy multi-* matching
  var ti = 0, pi = 0, star = -1, match = 0;
  while (ti < t.length) {
    if (pi < p.length && p.charAt(pi) === t.charAt(ti)) { ti++; pi++; }
    else if (pi < p.length && p.charAt(pi) === '*')     { star = pi++; match = ti; }
    else if (star !== -1)                               { pi = star + 1; ti = ++match; }
    else { return false; }
  }
  while (pi < p.length && p.charAt(pi) === '*') pi++;
  return pi === p.length;
}

// Build lookup maps
var eventScoreMap     = makeTableMap(eventScoringTable, 'event_name', 'event_score') || {};
var goalThresholdsMap = makeTableMap(goalThresholdsTable, 'goal_name', 'goal_threshold') || {};

// -----------------------------------------------------------------------------
// Read previous score from cookie
// -----------------------------------------------------------------------------
var prevScore = 0;
var cookieValues = getCookieValues(makeString(cookieName), false);
if (cookieValues.length > 0) {
  var rawCookieValue = cookieValues[0];
  var parts = makeString(rawCookieValue).split('|'); // tolerate legacy formats
  prevScore = makeInteger(parts[0]) || 0;
  if (prevScore > 100) prevScore = 100;
}

// -----------------------------------------------------------------------------
// Determine this event's score addition (no dedupe persistence)
// -----------------------------------------------------------------------------
var currentEventStr   = makeString(currentEvent);
var incomingEventName = makeString(copyFromDataLayer('event') || currentEventStr);
var addScore = 0;

// 1) Pattern match against the actual event name -> add table score for that name
if (currentEventStr && matchesPattern(incomingEventName, currentEventStr)) {
  addScore = makeInteger(eventScoreMap[incomingEventName]) || 0;
}

// 2) Literal fallback: use table score for the provided currentEvent
if (!addScore && eventScoreMap[currentEventStr] !== undefined) {
  addScore = makeInteger(eventScoreMap[currentEventStr]) || 0;
}

// Cap and compute new score
var newScore = prevScore + addScore;
if (newScore > 100) newScore = 100;

// -----------------------------------------------------------------------------
// Detect goal threshold *crossing* (prev < T ≤ new) and pick the highest crossed
// -----------------------------------------------------------------------------
var crossedGoal = null;
var crossedThreshold = -1;
for (var g in goalThresholdsMap) {
  if (goalThresholdsMap.hasOwnProperty(g)) {
    var th = makeInteger(goalThresholdsMap[g]);
    if (newScore >= th && prevScore < th && th >= crossedThreshold) {
      crossedThreshold = th;
      crossedGoal = g;
    }
  }
}

// -----------------------------------------------------------------------------
// Persist cookie + push synthetic event
// -----------------------------------------------------------------------------
// Build cookie options without defaults; include only provided values
var cookieOptions = {};
if (cookieDomain) cookieOptions['domain'] = makeString(cookieDomain);
if (cookieDaysRv && cookieDaysRv > 0) cookieOptions['max-age'] = cookieDaysRv * 24 * 60 * 60;
if (cookieSameSite) cookieOptions.samesite = makeString(cookieSameSite);
if (makeString(cookieSameSite).toLowerCase() === 'none') cookieOptions.secure = true; // required when SameSite=None

setCookie(makeString(cookieName), makeString(newScore), cookieOptions, cookieEncodeValue);

if (crossedGoal) {
  createQueue('dataLayer')({
    'event': 'goal_reached',
    'goal': makeString(crossedGoal),
    'lead_score': newScore
  });
}

if (debug) {
  logToConsole('[lead-score config]', {
    cookieName: cookieName,
    cookieDays: cookieDaysRv,
    cookieDomain: cookieDomain,
    cookieSameSite: cookieSameSite,
    currentEvent: currentEventStr,
    incomingEvent: incomingEventName,
    prevScore: prevScore,
    addScore: addScore,
    newScore: newScore,
    crossedGoal: crossedGoal,
    crossedThreshold: crossedThreshold
  });
}

data.gtmOnSuccess();


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
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "name"
                  },
                  {
                    "type": 1,
                    "string": "domain"
                  },
                  {
                    "type": 1,
                    "string": "path"
                  },
                  {
                    "type": 1,
                    "string": "secure"
                  },
                  {
                    "type": 1,
                    "string": "session"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "*"
                  },
                  {
                    "type": 1,
                    "string": "any"
                  },
                  {
                    "type": 1,
                    "string": "any"
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
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedKeys",
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

Created on 9/26/2025, 9:47:52 AM



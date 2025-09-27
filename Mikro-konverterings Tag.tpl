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
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// GTM Custom Tag Template: Visitor Event Lead Scoring

// Import required sandboxed APIs
const getCookieValues = require('getCookieValues');
const setCookie = require('setCookie');
const logToConsole = require('logToConsole');
const makeTableMap = require('makeTableMap');
const makeInteger = require('makeInteger');
const makeString = require('makeString');
const localStorage = require('localStorage');

// Template fields (these are set up in the GTM Template Editor UI)
const eventScoringTable = data.eventScoringTable; // [{event_name, event_score}]
const goalThresholdsTable = data.goalThresholdsTable; // [{goal_name, goal_threshold}]
const currentEvent = data.currentEvent; // e.g. 'session_engagement'

// Hardcoded cookie settings
const cookieName = 'lead_score'; // Hardcoded, not from data.cookieName
const cookieDays = 30;

// Defensive: ensure cookieName is a non-empty string
if (!cookieName || makeString(cookieName) === '') {
  logToConsole('ERROR: Cookie name is empty!');
  data.gtmOnFailure();
  return;
}

// Convert tables to maps for easy lookup
const eventScoreMap = makeTableMap(eventScoringTable, 'event_name', 'event_score');
const goalThresholdsMap = makeTableMap(goalThresholdsTable, 'goal_name', 'goal_threshold');

// Get current score from cookie
let score = 0;
const cookieValues = getCookieValues(makeString(cookieName), false);
if (cookieValues.length > 0) {
  const parts = cookieValues[0].split('|');
  score = makeInteger(parts[0]) || 0;
}

// Get scored events from localStorage
let scoredEvents = [];
const storedEvents = localStorage.getItem('lead_scored_events');
if (storedEvents) {
  scoredEvents = storedEvents.split(',');
}

// Only score if this event hasn't been scored yet
let eventScore = 0;
if (scoredEvents.indexOf(currentEvent) === -1) {
  eventScore = makeInteger(eventScoreMap[currentEvent]) || 0;
  score += eventScore;
  scoredEvents.push(currentEvent);
  localStorage.setItem('lead_scored_events', scoredEvents.join(','));
}

// Check if any goal threshold is crossed
let triggeredGoal = null;
for (const goalName in goalThresholdsMap) {
  const threshold = makeInteger(goalThresholdsMap[goalName]);
  if (score >= threshold) {
    triggeredGoal = goalName;
  }
}

// Update cookie with new score and goal (no event list)
let cookieValue = makeString(score);
if (triggeredGoal) {
  cookieValue += '|' + makeString(triggeredGoal);
} else {
  cookieValue += '|';
}

setCookie(makeString(cookieName), cookieValue, {
  'max-age': cookieDays * 24 * 60 * 60,
  path: '/',
  domain: 'auto'
}, false);

// Log goal trigger
if (triggeredGoal) {
  logToConsole('Lead Scoring Goal Triggered:', triggeredGoal, 'Score:', score);
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
                    "string": "lead_score"
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
        "publicId": "access_local_storage",
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
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "lead_scored_events"
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

Created on 9/26/2025, 9:47:52 AM



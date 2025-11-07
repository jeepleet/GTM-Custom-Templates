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
  "displayName": "Mikrokonverterings Tag",
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
    "type": "PARAM_TABLE",
    "name": "paramTable1",
    "displayName": "",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "cookieName",
          "displayName": "Cookie name",
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
          "displayName": "Expiration of cookie",
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
          "valueValidators": [
            {
              "type": "NON_EMPTY"
            }
          ],
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
          "name": "cookieHttpOnly",
          "checkboxText": "HttpOnly",
          "simpleValueType": true
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "CHECKBOX",
          "name": "cookieEncodeValue",
          "checkboxText": "Base64 Encode cookie",
          "simpleValueType": true
        },
        "isUnique": false
      }
    ],
    "newRowButtonText": "Cookie Configs"
  },
  {
    "type": "TEXT",
    "name": "currentEvent",
    "displayName": "Current Event Name",
    "simpleValueType": true,
    "help": "The event name to score for this tag execution."
  }
]


___SANDBOXED_JS_FOR_SERVER___

// GTM Server-Side Custom Tag Template: Visitor Event Lead Scoring (Server)

// Sandboxed APIs (Server)
const logToConsole = require('logToConsole');
const makeTableMap = require('makeTableMap');
const makeInteger = require('makeInteger');
const makeString = require('makeString');
const getType = require('getType');
const createRegex = require('createRegex');
const testRegex = require('testRegex');
const getCookieValues = require('getCookieValues');
const setCookie = require('setCookie');
const templateDataStorage = require('templateDataStorage');
const setResponseHeader = require('setResponseHeader');
const returnResponse = require('returnResponse');
const ObjectApi = require('Object');
const getEventData = require('getEventData');
const toBase64 = require('toBase64');
const fromBase64 = require('fromBase64');
const runContainer = require('runContainer');
const getRequestQueryParameter = require('getRequestQueryParameter');
const getRequestHeader = require('getRequestHeader');
const generateRandom = require('generateRandom');
const getTimestampMillis = require('getTimestampMillis');

// Template fields (configure these in the GTM Server Template UI)
const eventScoringTable = data.eventScoringTable; // [{event_name, event_score}]
const goalThresholdsTable = data.goalThresholdsTable; // [{goal_name, goal_threshold}]
const currentEvent = data.currentEvent; // e.g. 'session_engagement'

// Cookie configuration (configurable via template fields)
// Support either individual fields or a table `paramTable1` (first row used)
// Normalize string fields to avoid literal 'undefined'/'null' values coming from empty inputs
function normalizeStringField(value, fallback) {
	const str = makeString(value);
	if (value === undefined || value === null) return fallback;
	if (str === '' || str === 'undefined' || str === 'null') return fallback;
	return str;
}

const paramRows = data.paramTable1 && getType(data.paramTable1) === 'array' ? data.paramTable1 : [];
const row = paramRows.length > 0 ? paramRows[0] : {};

function getParam(key) {
	// Prefer row value if present, else top-level
	if (row && row[key] !== undefined) return row[key];
	return data[key];
}

const cookieName = normalizeStringField(getParam('cookieName'), 'lead_score');
const cookieDaysRaw = makeInteger(getParam('cookieExpirationDays'));
const cookieDays = cookieDaysRaw && cookieDaysRaw > 0 ? cookieDaysRaw : 30;
const cookieDomain = normalizeStringField(getParam('cookieDomain'), 'auto');
const cookieSameSite = normalizeStringField(getParam('cookieSameSite'), 'lax');
const cookieHttpOnly = !!getParam('cookieHttpOnly');
const cookieEncodeValue = !!getParam('cookieEncodeValue');

// Validate inputs
if (!cookieName || makeString(cookieName) === '') {
	logToConsole('ERROR: Cookie name is empty!');
	data.gtmOnFailure();
	return;
}

// Convert tables to maps
const eventScoreMap = makeTableMap(eventScoringTable, 'event_name', 'event_score') || {};
const goalThresholdsMap = makeTableMap(goalThresholdsTable, 'goal_name', 'goal_threshold') || {};

// Read current score from cookie
let score = 0;
const cookieValues = getCookieValues(makeString(cookieName), false);

if (cookieValues.length > 0) {
	let rawCookieValue = cookieValues[0];
	if (cookieEncodeValue) {
		const decoded = fromBase64(rawCookieValue);
		if (decoded !== undefined) {
			rawCookieValue = decoded;
		}
	}
	const parts = rawCookieValue.split('|');
	score = makeInteger(parts[0]) || 0;
	// Cap any existing cookie score at 100
	if (score > 100) {
		score = 100;
	}
}

// Server-side deduping of events per request/session using templateDataStorage
// Keyed by template + day to avoid unbounded growth; preview/editor storage is ephemeral
const storageKeyPrefix = 'lead_scored_events';
const storageKey = storageKeyPrefix;
let scoredEvents = templateDataStorage.getItemCopy(storageKey) || [];
if (getType(scoredEvents) !== 'array') {
	scoredEvents = [];
}

// Score this event (supports literal or regex-like input in currentEvent)
// If currentEvent looks like a regex, we match it against the actual incoming event name (from event data)
let eventScore = 0;
if (currentEvent) {
	let handled = false;
	const currentEventStr = makeString(currentEvent);

	// Determine the actual incoming event name from event data (fallback to provided string)
	const incomingEventName = makeString(
		getEventData('event_name') || getEventData('name') || getEventData('eventName') || currentEventStr
	);

	// Debug headers to help diagnose matching/lookup issues
	setResponseHeader('x-current-event-input', currentEventStr);
	setResponseHeader('x-incoming-event-name', incomingEventName);
	setResponseHeader('x-lookup-raw', makeString(eventScoreMap[incomingEventName]));

	// Slash-delimited regex like /pattern/i
	if (currentEventStr.length >= 2 && currentEventStr.charAt(0) === '/' && currentEventStr.lastIndexOf('/') > 0) {
		const lastSlash = currentEventStr.lastIndexOf('/');
		const pattern = currentEventStr.substring(1, lastSlash);
		const flags = currentEventStr.substring(lastSlash + 1);
		const regexObj = createRegex(pattern, flags);
		if (regexObj && testRegex(regexObj, incomingEventName)) {
			const addScore = makeInteger(eventScoreMap[incomingEventName]) || 0;
			if (addScore && scoredEvents.indexOf(incomingEventName) === -1) {
				score += addScore;
				eventScore += addScore;
				scoredEvents.push(incomingEventName);
			}
			handled = true;
		}
	}
	if (!handled) {
		// First, try literal match
		if (scoredEvents.indexOf(currentEventStr) === -1 && eventScoreMap[currentEventStr] !== undefined) {
			eventScore = makeInteger(eventScoreMap[currentEventStr]) || 0;
			score += eventScore;
			scoredEvents.push(currentEventStr);
			handled = true;
		}

		// If no literal match, attempt to treat entire input as a regex pattern without slashes, matched against the incoming event name
		if (!handled && currentEventStr) {
			const regexObj2 = createRegex(currentEventStr, 'i');
			if (regexObj2 && testRegex(regexObj2, incomingEventName)) {
				const addScore2 = makeInteger(eventScoreMap[incomingEventName]) || 0;
				if (addScore2 && scoredEvents.indexOf(incomingEventName) === -1) {
					score += addScore2;
					eventScore += addScore2;
					scoredEvents.push(incomingEventName);
				}
				handled = true;
			}
		}
	}
	templateDataStorage.setItemCopy(storageKey, scoredEvents);
}

// Cap the computed score at 100 before any further processing
if (score > 100) {
	score = 100;
}

// Determine triggered goal
let triggeredGoal = null;
for (const goalName in goalThresholdsMap) {
	const threshold = makeInteger(goalThresholdsMap[goalName]);
	if (score >= threshold) {
		triggeredGoal = goalName;
	}
}

// Build consent status from event data and query parameters (best-effort)
function normalizeConsentValue(value) {
	const str = makeString(value).toLowerCase();
	if (str === 'granted' || str === 'grant' || str === '1' || str === 'y' || str === 'yes' || str === 'true') {
		return 'granted';
	}
	if (str === 'denied' || str === 'deny' || str === '0' || str === 'n' || str === 'no' || str === 'false') {
		return 'denied';
	}
	return undefined;
}

function getConsentKey(path) {
	// Try nested consent object, then root event data, then query param
	const fromConsentObj = getEventData('consent.' + path);
	const fromRoot = getEventData(path);
	const fromQuery = getRequestQueryParameter(path);
	return normalizeConsentValue(fromConsentObj !== undefined ? fromConsentObj : (fromRoot !== undefined ? fromRoot : fromQuery));
}

const consentStatus = {};
const analyticsStorage = getConsentKey('analytics_storage');
if (analyticsStorage) consentStatus.analytics_storage = analyticsStorage;
const adStorage = getConsentKey('ad_storage');
if (adStorage) consentStatus.ad_storage = adStorage;
const adUserData = getConsentKey('ad_user_data');
if (adUserData) consentStatus.ad_user_data = adUserData;
const adPersonalization = getConsentKey('ad_personalization');
if (adPersonalization) consentStatus.ad_personalization = adPersonalization;
// Pass through Google Consent Mode transport signals if present
// Prefer headers (x-ga-gcs/x-ga-gcd), then event data/query fallbacks
const gcsHeader = makeString(getRequestHeader('x-ga-gcs') || '');
const gcdHeader = makeString(getRequestHeader('x-ga-gcd') || '');
const gcsString = makeString(gcsHeader || getEventData('gcs') || getRequestQueryParameter('gcs') || '');
const gcdString = makeString(gcdHeader || getEventData('gcd') || getRequestQueryParameter('gcd') || '');
if (gcsString) consentStatus.gcs = gcsString;
if (gcdString) consentStatus.gcd = gcdString;

// Derive GA4 client_id (required by GA4 if no client is present)
function deriveGa4ClientId() {
	// Prefer explicit values passed in request
	const explicitCid = makeString(getEventData('client_id') || getRequestQueryParameter('client_id') || getRequestQueryParameter('cid') || getRequestHeader('x-ga-cid') || '');
	if (explicitCid) return explicitCid;
	// Try from _ga cookie format GA1.1.XXXXXXXXXX.YYYYYYYYYY
	const gaCookies = getCookieValues('_ga', false);
	if (gaCookies && gaCookies.length > 0) {
		const parts = makeString(gaCookies[0]).split('.');
		if (parts.length >= 4) {
			const cid = parts[2] + '.' + parts[3];
			if (cid) return cid;
		}
	}
	// Fallback: synthesize a stable-ish id for this request
	const rand = generateRandom(100000000, 999999999);
	const ts = getTimestampMillis();
	return makeString(rand) + '.' + makeString(ts);
}
const clientId = deriveGa4ClientId();

// Update cookie with new score
let cookieValue = makeString(score);
if (cookieEncodeValue) {
	cookieValue = toBase64(cookieValue);
}

// Normalize SameSite option to one of 'strict' | 'lax' | 'none'
const sameSiteLower = makeString(cookieSameSite).toLowerCase();
const sameSiteOption = sameSiteLower === 'strict' ? 'strict' : (sameSiteLower === 'none' ? 'none' : 'lax');

setCookie(makeString(cookieName), cookieValue, {
	'domain': cookieDomain,
	'max-age': cookieDays * 24 * 60 * 60,
	path: '/',
	sameSite: sameSiteOption,
	httpOnly: cookieHttpOnly,
	secure: sameSiteOption === 'none'
}, false);

// Debug: surface resolved cookie config in preview headers
setResponseHeader('x-cookie-name', cookieName);
setResponseHeader('x-cookie-domain', cookieDomain);
setResponseHeader('x-cookie-days', makeString(cookieDays));
setResponseHeader('x-cookie-samesite', sameSiteOption);
setResponseHeader('x-cookie-httponly', cookieHttpOnly ? '1' : '0');
setResponseHeader('x-cookie-encoded', cookieEncodeValue ? 'base64' : '0');

// Optional: helpful response headers for debugging in preview
setResponseHeader('x-lead-score', makeString(score));
if (triggeredGoal) {
	setResponseHeader('x-lead-goal', makeString(triggeredGoal));
}

// If a goal is triggered, dispatch a synthetic event for downstream tags (e.g., Meta/Ads)
if (triggeredGoal) {
	runContainer({
		name: 'goal_reached',
		goal: makeString(triggeredGoal),
		lead_score: score,
		client_id: clientId,
		'x-ga-gcs': gcsString,
		'x-ga-gcd': gcdString
	});
	setResponseHeader('x-lead-dispatched', 'goal_reached');
	// Expose detected consent in debug headers
	setResponseHeader('x-consent-analytics', makeString(analyticsStorage || ''));
	setResponseHeader('x-consent-ad_storage', makeString(adStorage || ''));
	setResponseHeader('x-consent-ad_user_data', makeString(adUserData || ''));
	setResponseHeader('x-consent-ad_personalization', makeString(adPersonalization || ''));
	if (makeString(gcsString)) setResponseHeader('x-consent-gcs', gcsString);
	if (makeString(gcdString)) setResponseHeader('x-consent-gcd', gcdString);
}

// Must flush the response so cookies persist
returnResponse();

if (triggeredGoal) {
	logToConsole('Lead Scoring Goal Triggered (Server):', triggeredGoal, 'Score:', score);
}

data.gtmOnSuccess();


___SERVER_PERMISSIONS___

[
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
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
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
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
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
        "publicId": "run_container",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queryParameterAccess",
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

Created on 11/7/2025, 2:32:30 PM



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

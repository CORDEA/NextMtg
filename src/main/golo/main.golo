#!/usr/bin/env golosh
module NextMtg

import com.google.api.client.extensions.java6.auth.oauth2.AuthorizationCodeInstalledApp
import com.google.api.client.extensions.jetty.auth.oauth2.LocalServerReceiver
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow
import com.google.api.client.googleapis.auth.oauth2.GoogleClientSecrets
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport
import com.google.api.client.http.javanet.NetHttpTransport
import com.google.api.client.json.JsonFactory
import com.google.api.client.json.jackson2.JacksonFactory
import com.google.api.client.util.DateTime
import com.google.api.client.util.store.FileDataStoreFactory
import com.google.api.services.calendar.CalendarScopes

import java.io.File
import java.io.InputStream
import java.io.InputStreamReader

local function transport = ->
  GoogleNetHttpTransport.newTrustedTransport()

local function jsonFactory = ->
  JacksonFactory.getDefaultInstance()

local function scopes = ->
  list[CalendarScopes.CALENDAR_READONLY()]

function main = |args| {
}

local function credentials = {
  let factory = jsonFactory()
  let stream = NextMtg.class: getResourceAsStream("credentials.json")
  let secrets = GoogleClientSecrets.load(factory, InputStreamReader(stream))
  let flow = GoogleAuthorizationCodeFlow.Builder(
    transport(),
    factory,
    secrets,
    scopes()
  )
    : setDataStoreFactory(FileDataStoreFactory(File("tokens")))
    : setAccessType("offline")
    : build()

  let receiver = LocalServerReceiver.Builder()
    : setPort(8080)
    : build()

  return AuthorizationCodeInstalledApp(flow, receiver): authorize("user")
}

local function events = | credentials | {
  let service = Calendar.Builder(transport(), jsonFactory(), credentials)
    : setApplicationName("NextMtg")
    : build()

  let now = DateTime(System.currentTimeMillis())
  return service
    : events()
    : list("primary")
    : setMaxResults(1)
    : setSingleEvents(true)
    : execute()
    : getItems()
}

local function print = | events | {
  foreach event in events {
    println(event: getSummary())
  }
}

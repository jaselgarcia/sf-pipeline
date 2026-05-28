# Salesforce Pipeline

A collection of scripts for automating ETL from a salesforce database given a private key stored locally.
It will serve as a good starter project for exploring the use of apis and authenticated curl requests,
as well as a good practical use case for SQL and an introduction to invoking SQL scripts. 
It will build off of our inital work with forking out to curl via the URJ and IL apt listing web scrapers.

*It's vitally important that sensitive information is handled properly.*

[Salesforce API Reference](https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/intro_rest.htm)

## Dependencies
- perl-csv-tools
- jq
- libcurl
- Net:Curl::Easy
- Perl JSON module

## Scripts
- ~~**add-duplicate-info:** *very* specific script for one work-realted use case. Would look to refactor into something more generally useful.~~

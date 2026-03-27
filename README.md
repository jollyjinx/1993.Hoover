# Hoover

Hoover is an old Objective-C web crawler and indexing toolkit from the NeXTSTEP/OpenStep era. The codebase is centered around a crawler controller (`Hoover`), one or more remote fetch workers (`Fetcher` and `RBFetcher`), and a shared framework (`HooverFramework`) for URL parsing, HTML scanning, GDBM storage, queues, sockets, and utility classes.

This repository is archival. It was recovered from backups and still reflects its original structure, build files, and assumptions.

## What It Does

At a high level, Hoover:

1. Reads a crawler configuration from `HooverConfiguration`.
2. Seeds a crawl from configured URLs or from standard input.
3. Tracks per-site state, known paths, unknown paths, retry timing, and `robots.txt` rules.
4. Hands URL fetch work to remote worker processes over UDP/TCP.
5. Stores crawl state in either GDBM or an Enterprise Objects backed store.
6. Extracts links and text from fetched HTML for further crawling and indexing.

The code shows a strong focus on polite crawling for its time:

- `robots.txt` parsing via `RobotScanner`
- per-site scheduling and retry delays
- configurable link-following and same-site restrictions
- `If-Modified-Since` style crawl metadata
- HTML text extraction and link normalization

## Repository Layout

- `HooverFramework/`: Shared framework with URL parsing, HTML parsing, GDBM wrappers, queues, sockets, checksum helpers, and other infrastructure.
- `Hoover/`: Main crawler using a GDBM-backed persistent store.
- `HooverWithDBM/`: Alternate crawler variant using Enterprise Objects metadata and a PostgreSQL-backed EO model.
- `Fetcher/`: Early remote fetch worker implementation.
- `RBFetcher/`: Later fetch worker variant used with the `RockBot` naming/configuration.
- `DatabaseBuilder/`: Utility that reads fetcher output files and builds or updates a crawl database.
- `HTMLStripper/`: Utility that converts fetched HTML blobs into plain text.
- `URLSyntaxChecker/`: Small stdin/stdout utility that normalizes and validates URL syntax.
- `RockBot/`: Site-specific crawler variant for the RockBottom project, including extra EO model files and example runtime scripts.
- `GDBMTest/`: Small GDBM migration/inspection utility.
- `Sonstiges/`: Miscellaneous experiments and notes.

## Main Components

### `Hoover`

`Hoover` is the crawl controller. It loads `HooverConfiguration`, maintains persistent site state, schedules work, receives fetched pages back from workers, and writes the database on shutdown. It also reacts to signals:

- `SIGUSR1`: print current crawler status
- `SIGINT` / `SIGTERM`: save state and exit

The default configuration includes options such as:

- `followlinks`
- `stayonsites`
- `allpathsallowed`
- `maximumlinkdepth`
- `lastmodified`
- `useragentname`
- `databasename` or `eomodel`

If no `urls` section is present in the configuration, the crawler can read seed URLs from standard input.

### `Fetcher` and `RBFetcher`

The fetchers are remote worker processes. They advertise themselves to the controller over UDP, establish TCP connections back to Hoover, fetch URLs concurrently, and return crawl results. `RBFetcher` also writes fetched page payloads to `fetched/fetched.out*` files for later processing.

`RBFetcher` appears to be the more evolved worker in this repository:

- configurable user agent and filtering rules via `HTTPClient.configuration`
- multi-threaded worker model
- HTML extraction and indexing-related processing in `Worker.m`
- crawler port set to `20001`

The older `Fetcher` target uses a different controller port (`12345`) and appears to represent an earlier stage of the project.

### `HooverFramework`

The shared framework contains the reusable building blocks used across the tools:

- `HTMLScanner` and `HTMLDocument` for parsing URLs, links, and text from HTML
- `GDBMFile` and `GDBMCache` for persistent storage
- `TCPConnection` and `HFUDPSocket` for worker/controller communication
- `DatedQueue`, `MTQueue`, and `SortedArray` for scheduling and concurrency
- `MD5Checksum`, `FileWriter`, and other support classes

## Historical Build Notes

This project was built with NeXT Project Builder generated makefiles and expects the old `pb_makefiles` layout under `$(NEXT_ROOT)`. It is not a modern Xcode or Swift Package Manager project.

Build assumptions visible in the sources include:

- NeXTSTEP/OpenStep style Objective-C and Foundation
- Project Builder generated `Makefile`s
- `HooverFramework` installed as a framework
- GDBM headers/libraries
- `System.framework`
- `EOAccess.framework` and `EOControl.framework` for the EO-backed variants
- `lavl` for the framework build

There is also a historical `gnustep` branch in the repository, which suggests the code was at least partially adapted for GNUstep at some point.

## Likely Workflow

The intended workflow appears to have been:

1. Start `Hoover` with a configuration and a persistent database.
2. Start one or more `Fetcher` or `RBFetcher` worker processes, locally or on remote machines.
3. Let workers fetch pages and stream results back to the controller.
4. Optionally capture fetched output files.
5. Use tools like `DatabaseBuilder` and `HTMLStripper` to post-process the crawl data.

## Status

This is preserved historical source code, not a modernized crawler. Expect:

- legacy Objective-C memory management
- old Project Builder metadata (`PB.project`)
- outdated network and HTML assumptions
- machine-specific paths in some build files
- configuration and EO model files tied to the original environment

The repository is most useful as:

- an archive of an early custom web crawler
- a reference for the Hoover/RockBot codebase history
- a source base for future restoration or porting work

## License

This repository is licensed under the MIT License. See `LICENSE`.

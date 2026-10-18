# Save Data and Future Multiplayer Architecture

## Launch persistence principles

The first release should prioritise reliable local saves and offline operation. The exact file/database mechanism depends on the selected engine. Persist only the state needed: settings, owned fighters, unlock progress, currency, mastery if used, completed challenges, and schema version. Avoid saving transient combat state unless a future campaign requires checkpoints.

## Save reliability

- Use schema versions and migration functions.
- Write safely so interruption does not corrupt the only valid save where the chosen platform permits.
- Validate values on load; reject malformed numbers and unknown IDs safely.
- Apply match rewards through one authoritative local transaction-like path.
- Prevent duplicate rewards after rematch, repeated button events, or app resume.
- Provide a clear reset-save warning and test recovery behavior.
- Document that local data may not transfer to another device without cloud/account support.

## Identity boundaries

Offline local profile is not the same as an authenticated online account. Keep local player state separate from future server identity so migration is possible. Do not collect personal information for the initial offline game unless clearly needed and disclosed.

## Multiplayer requirements for future phase

Online design requires decisions and testing for:
- Authoritative match state and which system validates hits, health, cooldowns, and results.
- Synchronisation approach, latency handling, interpolation/prediction, and rollback research if required by combat speed.
- Matchmaking, lobbies, private rooms, rematches, player disconnects, and reconnection policy.
- Authentication, player identifiers, account recovery, progression ownership, and secure APIs.
- Validation against modified clients, forged results, duplicated rewards, and abusive traffic.
- Regional hosting, ongoing operating costs, monitoring, logging, privacy, and moderation/reporting policies.
- Device/network variation and fair handling of poor connections.

## Architecture now versus later

Now: cleanly separate combat inputs/events, fighter definitions, match rules, progression updates, and presentation. Use interfaces or modules where they make future authority boundaries clearer. Do not build elaborate networking abstractions without a concrete protocol or game need.

Later: select a tested networking solution and determine whether combat requires deterministic simulation or rollback. Refactor the combat simulation if necessary before adding ranked competition. Never assume local AI and offline play are equivalent to an online architecture.

## Competitive integrity

For online rewards and rankings, never trust client-submitted claims alone. Validate match completion and reward eligibility on trusted services or an appropriately authoritative host model. Add rate limits, replay/duplicate protection, and suspicious-result checks as appropriate. Do not sell online competitive advantages before balancing and policy review.

## Privacy and compliance

Before adding analytics, accounts, chat, purchases, or online social features, define data minimisation, user disclosure, retention, deletion, age-rating implications, and platform obligations. This document is architecture guidance, not legal advice.

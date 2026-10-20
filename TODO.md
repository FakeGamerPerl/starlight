# FakeGamer::Starlight - Project Roadmap & Task Tracker

A space logistics, traffic management, and life simulation engine written in Perl with SDL3.

- [x] Phase 0: Core Foundation & Physics Proof-of-Concept
  - [x] Coordinate-based distance calculation between celestial Hubs ($d = \sqrt{\Delta x^2 + \Delta y^2 + \Delta z^2}$).
  - [x] Dynamic mass calculation (empty dry mass + engines + cargo manifest).
  - [x] Thrust physics: speed driven by `current_thrust / total_mass` adjusted for corridor drag.
  - [x] Corridor degradation: rough lanes wear down ship engine integrity over ticks.
  - [x] State-triggered cargo degradation (food spoilage event and reputation penalty).
  - [x] Basic passenger lifecycle states (`okay` -> `tired` -> `panicked` -> `furious`).
  - [x] Headless text based simulation

- [ ] Phase 1: Corridor Capacity, Queues & Physical Tugboats
  - [ ] **Corridor Mass Bandwidth:**
    - [ ] Add `current_mass()` and `can_admit($ship)` to `Map::Corridor`.
    - [ ] Track all ships currently in-flight within a given corridor.
    - [ ] Stranded ships continue occupying mass capacity, choking lane throughput for other traffic.
  - [ ] **Hub Holding Orbits & Traffic Scheduling:**
    - [ ] Implement Hub holding queues (`$hub->queue`) for ships awaiting clearance.
    - [ ] Basic Dispatcher logic: FIFO queue admission.
    - [ ] Priority Dispatcher: Emergency/Passenger flights cut ahead of low-priority bulk ore.
  - [ ] **Tugboats as Physical Ships:**
    - [ ] Hubs maintain docked utility fleets (SAR tugs, tenders, shuttles).
    - [ ] Tugs have dedicated heavy-duty engines, high fuel consumption, and mass.
    - [ ] Dispatched tugs physically transit from the Hub into the corridor toward the stranded ship's coordinates.
    - [ ] Tug hookup: Tug locks onto stranded vessel; combined mass is calculated for the return/tow burn.
    - [ ] SAR fuel costs and operational wear billed back to the rescued ship or hub operating budget.
  - [ ] **Sister Ships:**
    - [ ] A company object with a list of owned ships.
    - [ ] A passing sister ship could take on cargo from slower or broken down ships.

- [ ] Phase 2: Economic Settlement & Port Logistics
  - [ ] **Post-Docking Settlement (`$hub->settle_ship($ship)`):**
    - [ ] Docking fees deducted from ship/company accounts.
    - [ ] Cargo liquidation: Ore and goods sold to Hub markets at local supply/demand rates.
    - [ ] Passenger fare collection (full fare for `okay`, reduced fare for `tired`, zero + settlement lawsuit for `furious`).
    - [ ] SAR rescue invoices: Tow charges billed to the ship's operator.
  - [ ] **Drydock & Maintenance:**
    - [ ] Hub engine repair and refueling services.
    - [ ] Corridor maintenance fund: percentage of tolls invested into repairing corridor `$quality`.

- [ ] Phase 3: Communications & Sensor Beacons
  - [ ] Communications relay network (hubs, satellites, corridor transponders).
  - [ ] Direct distress broadcasts (skips or drastically speeds up the "searching" phase when comms are in range).
  - [ ] Blind spots: unmapped lanes and deep-space corridors have packet delay or signal blackout.

- [ ] Phase 4: Automation & Scheduling Engine
  - [ ] **v1.0 Rule/Flowchart Engine:**
    - [ ] Node/rule table configuration for Hub dispatchers (e.g., `IF queue > 5 AND ship.priority > 8 THEN reroute`).
    - [ ] Dynamic congestion pricing: surge tolls applied during peak hours or degraded lane conditions.
  - [ ] **v2.0 Native Perl Automation Daemons:**
    - [ ] Scriptable event hooks (`on_transit_request`, `on_mayday`, `on_dock`).
    - [ ] Sandboxed execution via `Safe.pm` allowing custom scheduling algorithms.

- [ ] Phase 5: SDL3 / Affix Vector Visualization
  - [ ] Window bootstrap using CPAN `SDL3` via `Affix`.
  - [ ] 2D radar view (dradis from BSG?):
    - [ ] Hub nodes rendered with position coordinates.
    - [ ] Corridors drawn as vector lines (color-coded by quality: green/yellow/red).
    - [ ] Ships rendered as vector pips moving along corridor vectors.
    - [ ] Tugboats visibly traveling to meet stranded ships.
  - [ ] Real-time tick loop with pause/step controls (spacebar, tick rate slider).
  - [ ] Split-screen diagnostic telemetry HUD rendered via `SDL_ttf`.
  - [ ] Procedural audio notifications via `SDL_mixer` (dock chime, mayday klaxon).

- [ ] Phase 6: P2P Multiplayer via DHT
  - [ ] DHT client integration (bootstrap and infohash registration for star systems).
  - [ ] Direct peer handshake between players.
  - [ ] Inter-system jump corridors: ships dispatched across network sockets to arrive at other players' Hubs.
  - [ ] Shared commodity trade logs and contract bidding between connected systems.

use v5.40;
use lib '../lib';
use FakeGamer::Starlight;
#
my $earth_hub = FakeGamer::Starlight::Hub->new( id => 'HUB-EARTH-01', flag => 'Sol Transit Authority', mass => 50000, coordinates => [ 0, 0, 0 ] );
my $mars_hub
    = FakeGamer::Starlight::Hub->new( id => 'HUB-MARS-01', flag => 'Martian Mining Conglomerate', mass => 35000, coordinates => [ 250, 0, 0 ] );

# Jump corridor connecting Earth to Mars
my $corridor = FakeGamer::Starlight::Map::Corridor->new(
    id       => 'CORRIDOR-SOL-EM',
    name     => 'Earth-Mars Sublight Lane 1',
    points   => [ $earth_hub, $mars_hub ],
    quality  => 0.40,                           # Unmaintained lane
    capacity => 100000,
    drag     => 1.8                             # Medium gravitational drag
);

# Calibrated thrust: 15,000 units
my $engine = FakeGamer::Starlight::Engine->new(
    id     => 'ENG-ION-X2',
    fuel   => 'deuterium',
    power  => 15000,                            # thrust output
    mass   => 300,
    status => 100                               # factory fresh
);

# Manifest
my $cargo_food = FakeGamer::Starlight::Cargo::Food->new(
    id          => 'CRG-FOOD-99',
    flag        => 'Earth Agri',
    type        => 'food',
    mass        => 100,
    destination => 'HUB-MARS-01',
    priority    => 8,
    lifespan    => 12                           # Will spoil early on tick 12
);
my $cargo_passenger = FakeGamer::Starlight::Cargo::Person->new(
    id          => 'CRG-PAX-01',
    name        => 'Dr. Spaceman',
    flag        => 'Civilian',
    type        => 'passenger',
    mass        => 75,
    destination => 'HUB-MARS-01',
    priority    => 10,
    pockets     => 4500,
    tolerance   => 3.5,
    status      => 'okay'
);
my $cargo_ore = FakeGamer::Starlight::Cargo::Ore->new(
    id          => 'CRG-ORE-01',
    flag        => 'Martian Mining',
    type        => 'ore',
    mass        => 800,
    destination => 'HUB-MARS-01',
    priority    => 2
);

# Hero ship
my $ship = FakeGamer::Starlight::Ship->new(
    id       => 'SHP-VALKYRIE',
    name     => 'SS Valkyrie',
    flag     => 'Free Traders',
    mass     => 1500,
    engines  => [$engine],
    manifest => [ $cargo_food, $cargo_passenger, $cargo_ore ]
);

# System
my $system = FakeGamer::Starlight::System->new(
    id          => 'SOL',
    name        => 'Sol Sector 01',
    coordinates => [ 0, 0, 0 ],
    hubs        => [ $earth_hub, $mars_hub ],
    corridors   => [$corridor],
    ships       => [$ship]
);
say sprintf q[Ship '%s' loaded. Dry Mass: %d kg | Total Mass: %d kg], $ship->name, $ship->empty_mass, $ship->total_mass;
say 'Departing ' . $earth_hub->name . ' -> entering ' . $corridor->name;
$ship->enter_corridor( $corridor, $mars_hub );

# Run simulation
for ( 1 .. 120 ) {
    $system->tick();
    my $t   = $ship->transit;
    my $pct = $t ? int( $t->{progress} * 100 ) : 100;
    $pct = 100 if $pct > 100;
    my $bar_len = 20;
    my $filled  = int( ( $pct / 100 ) * $bar_len );
    my $bar     = '[' . ( '=' x $filled ) . ( ' ' x ( $bar_len - $filled ) ) . ']';
    my $mode    = $t ? uc( $t->{rescue_state} ) : 'DOCKED';
    say sprintf 'Tick %02d | %s %3d%% | Mode: %-9s | Eng: %3d%% | Pax: %-8s | Rep: %2d', $system->ticks, $bar, $pct, $mode, $engine->status,
        $cargo_passenger->status, $ship->reputation;
    last unless $ship->transit;
}
say 'Docked Ships at ' . $mars_hub->name . ': ' . scalar( @{ $mars_hub->docked } );
say 'SS Valkyrie Final Reputation: ' . $ship->reputation . '/100';
say 'SS Valkyrie Engine Condition: ' . $engine->status . '/100';
say 'Dr. Spaceman Condition: ' . $cargo_passenger->status;

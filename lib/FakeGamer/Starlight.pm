use v5.40;

package FakeGamer::Starlight v0.0.1 {
    use experimental 'class';
    use Data::Printer;

    class FakeGamer::Starlight::Engine {
        field $id     : param : reader;          # registry id
        field $fuel   : param : reader;          # required fuel type
        field $power  : param : reader;          # power requirements to ignite
        field $mass   : param : reader;          #
        field $thrust : param : reader = [];     # rough curve over fuel
        field $status : param : reader = 100;    # broken (0), worn (50), perfect (100)

        method degrade($amount) {
            $status = ( $status - $amount < 0 ) ? 0 : $status - $amount;
        }
    }

    class FakeGamer::Starlight::Construct {
        field $id      : param : reader;  # registry id
        field $flag    : param : reader;  # company/group ship is affiliated with (might gain discounts at company-owned hubs, priority service, etc.)
        field $name    : param : reader = $id;    # optional name (may be user defined in the future but defaults to $id)
        field $mass    : param : reader;          # dry / empty mass
        field $engines : param : reader //= [];    # list of ::Engine
        field $status  : param : reader //= {};    # power generation, life support, fuel levels, damage, etc.
        field $roles   : param : reader //= []
            ; # jump point (corridor), slingshot (jump through unmapped space; may be dangerous), warehouse, refuel station, tourism, passenger transfer, mapping, communications, etc.
        field $requirements : param : reader //= {};    # docking requirements, limits on what can be stored and for how long, etc.
        field $capacities   : param : reader //= {};    # size of warehouses, passenger quarters, etc.
        field $reputation   : param : reader = 70;      # damaged/lost cargo? dead passengers? no fuel? no one will want to use this ship/hub

        #
        method empty_mass () {
            my $m = $mass;
            $m += $_->mass for @$engines;
            $m;
        }

        method current_thrust () {
            my $total = 0;

            # engine status scales output; power acts as base thrust
            $total += $_->power * ( $_->status / 100.0 ) for @$engines;
            $total;
        }

        method adjust_reputation ($amount) {
            $reputation += $amount;
            $reputation = 100 if $reputation > 100;
            $reputation = 0   if $reputation < 0;
        }
    }

    class FakeGamer::Starlight::Ship : isa(FakeGamer::Starlight::Construct) {
        field $manifest : param : reader //= [];    # list of ::Cargo items
        field $transit : reader = undef;    # Flight navigation state like { corridor => $obj, progress => 0.0, speed => 0.1, destination => $hub }

        #
        method total_mass() {
            my $m = $self->empty_mass;
            $m += $_->mass for @$manifest;
            $m;
        }

        method enter_corridor ( $corridor, $dest ) {
            $transit = {
                corridor    => $corridor,
                progress    => 0.0,
                destination => $dest,

                # XXX - if a ship is lost, we gotta find it
                rescue_state   => 'normal',    # normal -> stranded -> searching -> towing
                search_ticks   => 0,
                stranded_ticks => 0
            };
        }

        method advance_transit ($delta) {
            return unless $transit;
            $transit->{progress} += $delta;
        }
        method clear_transit () { $transit = undef }
    };

    class FakeGamer::Starlight::Hub : isa(FakeGamer::Starlight::Construct) {
        field $coordinates : param :
            reader;    # 3d position in star system (may be stationary from nearst large body or move if part of a charting mission)
        field $fees   : param : reader //= {};    # a price list for storing, docking, transfer, etc.
        field $docked : param : reader //= [];    # Ships currently docked
        field $queue  : param : reader //= [];    # ships waiting for corridors

        method dock_ship ($ship) {
            push @$docked, $ship;
            $ship->clear_transit;
        }

        method undock_ship ($ship_id) {
            my ($ship) = grep { $_->id eq $ship_id } @$docked;
            @$docked = grep { $_->id ne $ship_id } @$docked;
            $ship;
        }
    };

    class FakeGamer::Starlight::Cargo {
        field $id          : param : reader;
        field $flag        : param : reader;    # company/group affiliation
        field $type        : param : reader;    # passenger, fuel, mechanical, ore, etc.
        field $mass        : param : reader;
        field $destination : param : reader;    # where this item should end up
        field $priority    : param : reader;    # how important is it that this gets there quickly
    }

    class FakeGamer::Starlight::Cargo::Food : isa(FakeGamer::Starlight::Cargo) {
        field $lifespan : param : reader;       # time left before spoilage
        field $spoiled : reader = 0;

        method age_one_tick () {
            return 0 if $spoiled;
            $lifespan--;
            if ( $lifespan <= 0 ) {
                $spoiled = 1;
                return -1;    # when I get around to event triggers, this would signal us that the food just spoiled
            }
            1;                # still fresh
        }
    }

    class FakeGamer::Starlight::Cargo::Fuel : isa(FakeGamer::Starlight::Cargo) {
    }

    class FakeGamer::Starlight::Cargo::Machinery : isa(FakeGamer::Starlight::Cargo) {
    }

    class FakeGamer::Starlight::Cargo::Ore : isa(FakeGamer::Starlight::Cargo) {
    }

    class FakeGamer::Starlight::Cargo::Person : isa(FakeGamer::Starlight::Cargo) {
        field $name      : param : reader;
        field $pockets   : param : reader;                        # money they're holding
        field $status    : param : reader : writer //= 'okay';    # enum: okay, sick, tired, starving, dead, cryosleep pod, etc.
        field $tolerance : param :
            reader;    # G force tolerance; if a ship takes a slingshot route or high G-maneuever, their status drops from okay -> sick -> injured
    }

    class FakeGamer::Starlight::Map {
        field $charts : param : reader;
        field $status : param : reader;    # public, private (to a single ship/user), company (to a single group of ships and/or hubs)
    }

    class FakeGamer::Starlight::Map::Corridor {
        field $id      : param : reader;          # id
        field $name    : param : reader = $id;    # maybe it's a well known path, idk...
        field $points  : param : reader;          # list of 2 or more destinations [ $hub_a, $hub_b ]
        field $quality : param : reader
            ; # 0.0..1.0; well maintained jump corridor provides smooth transit, neglected causes engine wear and ship damage if really bad. Hubs use toll money to maintain corridors, bad corridors lower hub reputation
        field $capacity : param : reader; # max mass limit of corridor (total not per ship; creates a queue for entry and monitored by local jump hub)
        field $drag : param : reader
            ; # gravitational(?) value that slows ships in transit; high-drag corridor requires ships to burn continuous propellant to maintain gate velocity, favoring light ships over heavy ore haulers
        field $status : param : reader //= {};    # simple open/closed; toggles when being maintained, remapped to account for drift, etc.

        #
        method wear_factor () {
            return ( 1.0 - $quality ) * 5;        # Remember: neglected corridors cause engine damage
        }

        method distance () {
            my ( $p1, $p2 ) = @$points;
            my ( $x1, $y1, $z1 ) = @{ $p1->coordinates };
            my ( $x2, $y2, $z2 ) = @{ $p2->coordinates };
            return sqrt( ( $x2 - $x1 )**2 + ( $y2 - $y1 )**2 + ( $z2 - $z1 )**2 );
        }
    }

    class FakeGamer::Starlight::System {    # star system, cluster, gravitational body, etc.
        field $id          : param : reader;         # registry number of local star/gravitational body
        field $name        : param : reader = $id;
        field $coordinates : param : reader;
        field $ticks       : param : reader //= 0;
        field $hubs        : param : reader //= [];
        field $ships       : param : reader //= [];
        field $corridors   : param : reader //= [];
        field $elements    : param : reader = [];    # other star systems if a cluster?

        method tick () {
            $ticks++;

            # XXX - update celestial positions / orbits
            # advance ships along corridors (consume fuel, apply drag/wear)
            for my $ship (@$ships) {
                my $transit  = $ship->transit or next;
                my $corridor = $transit->{corridor};
                my $thrust   = $ship->current_thrust;
                if ( $thrust > 0 && $transit->{rescue_state} eq 'normal' ) {

                    # powered flight: speed scales with thrust / mass minus drag
                    my $effective_speed = ( $thrust / $ship->total_mass ) * ( 1.0 - ( $corridor->drag * 0.1 ) );
                    $effective_speed = 0 if $effective_speed < 0;
                    my $progress_delta = $effective_speed / $corridor->distance;
                    $ship->advance_transit($progress_delta);

                    # engine wear in neglected corridors
                    if ( $corridor->quality < 0.5 ) {
                        $_->degrade( $corridor->wear_factor ) for @{ $ship->engines };
                    }
                }
                else {
                    # out of fuel, engine failure, id... send out a search and rescue team
                    $self->handle_stranded_ship( $ship, $transit, $corridor );
                }

                # arrival check
                if ( $transit->{progress} >= 1.0 ) {
                    my $dest_hub = $transit->{destination};
                    $dest_hub->dock_ship($ship);
                    say sprintf( "[TICK %02d] Ship %s has DOCKED at %s", $ticks, $ship->name, $dest_hub->name );
                }
            }

            # XXX - process hub queues & gate departures
            # check cargo & passenger states (spoilage, satisfaction)
            for my $ship (@$ships) {
                my $transit = $ship->transit;
                for my $cargo ( @{ $ship->manifest } ) {

                    # food spoilage
                    if ( $cargo->isa('FakeGamer::Starlight::Cargo::Food') ) {
                        if ( $cargo->age_one_tick == -1 ) {
                            say '[ALERT] Food cargo on ' . $ship->name . ' has spoiled!';
                            $ship->adjust_reputation(-15);    # spoiled food knocks ship's reputation
                        }
                    }

                    # pax comfort
                    if ( $cargo->isa('FakeGamer::Starlight::Cargo::Person') ) {
                        if ( $transit && $transit->{rescue_state} ne 'normal' ) {

                            # pax deteriorate while stranded
                            if ( $cargo->status eq 'tired' && $transit->{stranded_ticks} >= 6 ) {
                                $cargo->set_status('panicked');
                                say sprintf( "[LIFE SIM Tick %02d] %s is PANICKING!", $ticks, $cargo->name );
                                $ship->adjust_reputation(-5);
                            }
                            elsif ( $cargo->status eq 'panicked' && $transit->{stranded_ticks} >= 14 ) {
                                $cargo->set_status('furious');
                                say sprintf( "[LIFE SIM Tick %02d] %s is now FURIOUS with transit management!", $ticks, $cargo->name );
                                $ship->adjust_reputation(-10);
                            }
                        }
                        elsif ( $transit && $cargo->status eq 'okay' && rand() < 0.05 ) {
                            $cargo->set_status('tired');
                        }
                    }
                }
            }

            method handle_stranded_ship ( $ship, $transit, $corridor ) {
                $transit->{stranded_ticks}++;
                if ( $transit->{rescue_state} eq 'normal' ) {
                    say sprintf(
                        "[MAYDAY Tick %02d] %s suffered ENGINE FAILURE! Stranded at %d%% along %s.",
                        $ticks, $ship->name, int( $transit->{progress} * 100 ),
                        $corridor->name
                    );
                    $transit->{rescue_state} = 'searching';
                    $transit->{search_ticks} = 0;
                }
                elsif ( $transit->{rescue_state} eq 'searching' ) {
                    $transit->{search_ticks}++;

                    # without comms beacons, search takes time. Discovery chance rises over ticks:
                    my $found_chance = $transit->{search_ticks} * 0.12;
                    if ( rand() < $found_chance || $transit->{search_ticks} >= 12 ) {
                        say sprintf(
                            "[RESCUE Tick %02d] SAR Tug from %s has LOCATED %s! Tow cable locked.",
                            $ticks, $transit->{destination}->name,
                            $ship->name
                        );
                        $transit->{rescue_state} = 'towing';
                        $ship->adjust_reputation(-5);    # SAR dispatch penalty
                    }
                }
                elsif ( $transit->{rescue_state} eq 'towing' ) {

                    # Tug pulls ship along the lane at a steady 5 distance units per tick
                    my $tug_speed      = 5.0;
                    my $progress_delta = $tug_speed / $corridor->distance;
                    $ship->advance_transit($progress_delta);
                }
            }
        }
    }
};
1;
__END__
=encoding utf-8

=head1 NAME

FakeGamer::Starlight - Space!

=head1 SYNOPSIS

    use FakeGamer::Starlight;
    ...;

=head1 DESCRIPTION

Space!

=head1 See Also

TODO

=head1 LICENSE

This software is Copyright (c) 2026 by Sanko Robinson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

See the F<LICENSE> file for full text.

=head1 AUTHOR

Sanko Robinson <https://github.com/sanko>

=begin stopwords


=end stopwords

=cut

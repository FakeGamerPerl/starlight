requires 'SDL3', 'v0.0.6';
requires 'perl', 'v5.40.0';
on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
    requires 'perl',                'v5.40.0';
};

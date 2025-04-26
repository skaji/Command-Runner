my @prereq = (
    [ Prereqs => 'ConfigureRequires' ] => [
        'Module::Build::Tiny' => '0.051',
        'perl' => '5.008001',
    ],
    [ Prereqs => 'DevelopRequires' ] => [
        'File::Which' => '0',
    ],
    [ Prereqs => 'RuntimeRequires' ] => [
        'Capture::Tiny' => '0',
        'File::pushd' => '0',
        'String::ShellQuote' => '0',
        'Win32::ShellQuote' => '0',
        'perl' => '5.008001',
    ],
    [ Prereqs => 'TestRequires' ] => [
        'Test::More' => '0.98',
    ],
);

my @plugin = (
    'ExecDir' => [ dir => 'script' ],
    'Git::GatherDir' => [ exclude_filename => 'META.json', exclude_filename => 'LICENSE' ],
    'CopyFilesFromBuild' => [ copy => 'META.json', copy => 'LICENSE' ],
    'VersionFromMainModule' => [],
    'LicenseFromModule' => [ override_author => 1 ],
    'ReversionOnRelease' => [ prompt => 1 ],
    'NextRelease' => [ format => '%v  %{yyyy-MM-dd HH:mm:ss VVV}d%{ (TRIAL RELEASE)}T' ],
    'Git::Check' => [ allow_dirty => 'Changes', allow_dirty => 'META.json' ],
    'GithubMeta' => [ issues => 1 ],
    'ReadmeAnyFromPod' => [ type => 'markdown', filename => 'README.md', location => 'root' ],
    'MetaProvides::Package' => [ inherit_version => 0, inherit_missing => 0 ],
    'PruneFiles' => [ filename => 'dist.pl', filename => 'README.md', match => '^(xt|author|maint|example|eg)/' ],
    'GitHubREADME::Badge' => [ badges => 'github_actions/test.yml' ],
    'GenerateFile' => [ filename => 'Build.PL', content => "use Module::Build::Tiny;\nBuild_PL();" ],
    'MetaJSON' => [],
    'Metadata' => [ x_static_install => 1 ],
    'Git::Contributors' => [],
    'License' => [],

    'CheckChangesHasContent' => [],
    'ConfirmRelease' => [],
    'UploadToCPAN' => [],
    'CopyFilesFromRelease' => [ match => '\.pm$' ],
    'Git::Commit' => [ commit_msg => '%v', allow_dirty => 'Changes', allow_dirty => 'META.json', allow_dirty_match => '\.pm$' ],
    'Git::Tag' => [ tag_format => '%v', tag_message => '%v' ],
    'Git::Push' => [],
);

my @config = (
    name => 'Command-Runner',
    [ @prereq, @plugin ],
);

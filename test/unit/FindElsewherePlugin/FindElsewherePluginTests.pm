use strict;

package FindElsewherePluginTests;

use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

#use base qw(FoswikiTestCase);

use strict;

#use Foswiki::UI::Save;
use Error qw( :try );
use Foswiki::Plugins;
use Foswiki::Plugins::FindElsewherePlugin;

my $expected;
my $source;

#my $foswiki;

sub setLocalSite {
    $Foswiki::cfg{Plugins}{FindElsewherePlugin}{Enabled} = 1;
    $Foswiki::cfg{Plugins}{FindElsewherePlugin}{Module} =
      'Foswiki::Plugins::FindElsewherePlugin';
}

sub loadExtraConfig {
    my $this = shift;
    $this->SUPER::loadExtraConfig();
    setLocalSite();
}

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();

    my $query;
    eval {
        require Unit::Request;
        require Unit::Response;
        $query = new Unit::Request("");
    };
    if ($@) {
        $query = new CGI("");
    }
    $query->path_info( "/" . $this->{test_web} . "/TestTopic" );
    $this->{session}->finish() if ( defined( $this->{session} ) );
    $this->{session} = new Foswiki( undef, $query );
    $Foswiki::Plugins::SESSION = $this->{session};

    $Foswiki::cfg{LocalSitePreferences} = "$this->{users_web}.SitePreferences";

    Foswiki::Func::saveTopic( $this->{users_web}, 'ProjectContributor', undef,
        "Some text" );
    Foswiki::Func::saveTopic( $this->{users_web}, 'SomeMissingTopic', undef,
        "Some text" );
}

sub doTest {
    my ( $this, $source, $expected, $assertFalse ) = @_;

    _trimSpaces($source);
    _trimSpaces($expected);

    #print " SOURCE   = $source\n EXPECTED = $expected \n";

    $source = Foswiki::Func::expandCommonVariables($source);
    Foswiki::Plugins::FindElsewherePlugin::initPlugin( "TestTopic",
        $this->{test_web}, "MyUser", "System" );
    Foswiki::Plugins::FindElsewherePlugin::preRenderingHandler( $source,
        $this->{test_web} );

    #print " RENDERED = $source \n";
    if ($assertFalse) {
        $this->assert_str_not_equals( $expected, $source );
    }
    else {
        $this->assert_str_equals( $expected, $source );
    }
}

=pod

---++ Plurals to Singular

=cut

# ########################################################
# Verify that a topic is properly found as a plural
# ########################################################
sub test_PluralToSingularMultipleWeb {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'DISABLEPLURALTOSINGULAR', '0' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK',              '0' );

    $source = <<END_SOURCE;
Test ProjectContributors Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test <nop/>ProjectContributors<sup>([[$this->{users_web}.ProjectContributors][$this->{users_web}]],[[System.ProjectContributors][System]])</sup> Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

    Foswiki::Func::setPreferencesValue( 'DISABLEPLURALTOSINGULAR', '1' );

    $this->doTest( $source, $expected, 1 );
}

=pod

---++ Spaced wikiWord

=cut

sub test_SpacedWikiWord {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'DISABLEPLURALTOSINGULAR', '0' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK',              '0' );

    $source = <<END_SOURCE;
Test [[Installation Guide]] Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test [[System.InstallationGuide][Installation Guide]] Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Multiple web linking

=cut

# ########################################################
# Verify that a topic is properly found in multiple webs
# ########################################################
sub test_SpacedMultiwebTopic {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test [[Project Contributor]] Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test <em>Project Contributor</em><sup>([[$this->{users_web}.ProjectContributor][$this->{users_web}]],[[System.ProjectContributor][System]])</sup> Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Test not-found links

=cut

# ########################################################
# Verify that a missing topic doesn't loose it's [[]] notation
# ########################################################
sub test_NotFoundWikiWords {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test [[AnotherMissingOne]] Word
Test OneMoreMissing Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test [[AnotherMissingOne]] Word
Test OneMoreMissing Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Multiple web linking

=cut

# ########################################################
# Verify that a topic is properly found in multiple webs
# ########################################################
sub test_MultiWebTopic {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test ProjectContributor Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test <nop/>ProjectContributor<sup>([[$this->{users_web}.ProjectContributor][$this->{users_web}]],[[System.ProjectContributor][System]])</sup> Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Look Elsewhere for Local

=cut

# ########################################################
# Verify that an explicit local topic is found in a remote
# location if locally missing.
# ########################################################
sub test_LookElsewhereForLocal {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        "$this->{users_web}, System" );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK',            '0' );
    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREFORLOCAL', '1' );

    $source = <<"END_SOURCE";
Test $this->{test_web}.SomeMissingTopic Word
Test [[$this->{test_web}.SomeMissingTopic][Link text]] Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test [[$this->{users_web}.SomeMissingTopic][SomeMissingTopic]] Word
Test [[$this->{users_web}.SomeMissingTopic][Link text]] Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREFORLOCAL', '0' );

    $this->doTest( $source, $expected, 1 );

}

=pod

---++ Multiple web linking with macro webnames

=cut

# ########################################################
# Verify that a topic is properly found in multiple webs
# Item10460: Webs identified by macro - %USERSWEB% and %SYSTEMWEB%
# ########################################################
sub test_MultiWebTopicMacros {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        '%USERSWEB%, %SYSTEMWEB%' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test ProjectContributor Word
END_SOURCE

    $expected = <<"END_EXPECTED";
Test <nop/>ProjectContributor<sup>([[$this->{users_web}.ProjectContributor][$this->{users_web}]],[[System.ProjectContributor][System]])</sup> Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Email address with WikiWord on left

=cut

# ########################################################
# Item11199: WikiWords linked incorrectly in email addresses
# ########################################################
sub test_WikiWordAsEmailAddress {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        '%USERSWEB%, %SYSTEMWEB%' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<'END_SOURCE';
Test ProjectContributor@example.com Word
END_SOURCE

    $expected = <<'END_EXPECTED';
Test ProjectContributor@example.com Word
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

=pod

---++ Look elsewhere for acronyms

=cut

# ########################################################
# Verify that an acronym is handled per first, all, none setting
# ########################################################
sub test_LookElsewhereForAcronyms {
    my $this = shift;

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREWEBS',
        '%USERSWEB%, %SYSTEMWEB%' );
    Foswiki::Func::setPreferencesValue( 'NOAUTOLINK', '0' );

    $source = <<END_SOURCE;
Test ACRONYM Word
And another ACRONYM here
END_SOURCE

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREFORACRONYMS', 'none' );

    $expected = <<"END_EXPECTED";
Test ACRONYM Word
And another ACRONYM here
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREFORACRONYMS', 'first' );

    $expected = <<"END_EXPECTED";
Test [[System.ACRONYM][ACRONYM]] Word
And another ACRONYM here
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

    Foswiki::Func::setPreferencesValue( 'LOOKELSEWHEREFORACRONYMS', 'all' );

    $expected = <<"END_EXPECTED";
Test [[System.ACRONYM][ACRONYM]] Word
And another [[System.ACRONYM][ACRONYM]] here
END_EXPECTED

    $this->doTest( $source, $expected, 0 );

}

# ####################
# Utility Functions ##
# ####################

sub _trimSpaces {

    #my $text = $_[0]

    $_[0] =~ s/^[[:space:]]+//s;    # trim at start
    $_[0] =~ s/[[:space:]]+$//s;    # trim at end
}

1;

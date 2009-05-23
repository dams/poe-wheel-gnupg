#!/usr/bin/perl
use POE qw(Wheel::GnuPG);

POE::Session->create(
    inline_states => {
      _start => sub {

        # let's say I have a file I want to decrypt
        use IO::File;
#        $_[HEAP]{encrypted_fh} = IO::File->new('encrypted_file.asc', 'r');
        $_[HEAP]{encrypted_fh} = IO::File->new('/Users/dams/scratchpad/plop3.asc', 'r');


        my $gnupg = POE::Wheel::GnuPG->new(
          ready_to_input_data => 'ready_to_input_data',
          ready_to_input_passphrase => 'ready_to_input_passphrase',
          something_on_stdout => 'something_on_stdout',
          something_on_status => 'something_on_status',
          something_on_error => 'something_on_error',
          something_on_logger => 'something_on_logger',
		  end_of_process => 'the_end',
        );
        $_[HEAP]{gnupg} = $gnupg;
        $gnupg->options->hash_init( armor   => 1,
                                    homedir => '/Users/dams/.gnupg' );
        $gnupg->options->meta_interactive( 0 );
        $gnupg->decrypt();
      },
      ready_to_input_passphrase => sub {
        my $passphrase_fh = $_[ARG0];
        print $passphrase_fh "vbl383383";

        # this is important to let the decryption start
		$_[HEAP]{gnupg}->finished_writing_passphrase();
      },
      ready_to_input_data => sub {
        my $input_fh = $_[ARG0];
        my $encrypted_fh = $_[HEAP]{encrypted_fh};
        if (eof($encrypted_fh)) {
          # it's the end of the encrypted file
          $_[HEAP]{gnupg}->finished_writing_input();
        } else {
		  my $line = <$encrypted_fh>;
          print $input_fh $line;
        }
      },
      something_on_status => sub {
          my $status_fh = $_[ARG0];
          return if eof $status_fh;
          my @status = <$status_fh>;
          print STDERR " got status : @status\n";
      },
      something_on_error => sub {
          my $err_fh = $_[ARG0];
          return if eof $err_fh;
          my @errors = <$err_fh>;
          print STDERR " got errors : @errors\n";
      },
      something_on_stdout => sub {
		  my $stdout_fh = $_[ARG0];
          return if eof $stdout_fh;
          my @output = <$stdout_fh>;
          my @uppercased_output = map { uc } @output;
          print "got output, uppercased : @uppercased_output\n";
      },
      something_on_logger => sub {
		  my $logger_fh = $_[ARG0];
          return if eof $logger_fh;
          my @logger = <$logger_fh>;
          print STDERR "got logger : : @logger\n";
      },
      the_end => sub {
          $_[HEAP]{gnupg}->destroy();
          print STDERR " --- the end --- \n";
          POE::Kernel->stop();
      },
    }
  );

POE::Kernel->run();
print "all good.\n";
exit();

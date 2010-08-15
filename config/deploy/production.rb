set :branch, 'master'

set :user, 'ubuntu'

# SSH Options (put a symlink in your .ssh dir if the key file isn't located there)
ssh_options[:keys] = %w(~/.ssh/burt-id_rsa-gsg-keypair)

role :app, 'dada.byburt.com'

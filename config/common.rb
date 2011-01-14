# Paths
set :app_root, proc { File.join(root, 'app') }
set :gen_root, proc { File.join(root, 'gen') }
set :schema_root, proc { File.join(root, 'schema') }

# Cache
set :templates, {}

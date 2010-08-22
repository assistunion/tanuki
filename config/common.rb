# Paths
set :app_root, proc { File.join(root, 'app') }
set :cache_root, proc { File.join(root, 'cache') }
set :schema_root, proc { File.join(root, 'schema') }
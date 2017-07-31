# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
Path.join(["rel", "plugins", "*.exs"])
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"%b8!:@Sx~O]%Y.qC8Vej)vkHEmx*GSx=Y&T/dnijJ^wf|U__Ki!Rr|8ab.P8e0R5"
end

environment :kube do
  set include_erts: true
  set include_src: false
  set vm_args: "rel/vm.args"
  set cookie: :"aoqq6!)u9Y3N<12U&R}h;tu@mOu6)c@ADY<]h?Ib6Ir^[d|(m~F2/Zhoa[D3x,.r"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"aoqq6!)u9Y3N<12U&R}h;tu@mOu6)c@ADY<]h?Ib6Ir^[d|(m~F2/Zhoa[D3x,.r"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :ltse_poc do
  set version: current_version(:ltse_poc)
  set applications: [
    :runtime_tools
  ]
end


module Nanoc::Extra
  # @api private
  module FishAutocompletion
    def generate
      root_cmd = Nanoc::CLI.root_command

      buf = ''

      # global options
      # FIXME: insert -x if necessary
      buf << "# global options\n"
      root_cmd.option_definitions.each do |opt_def|
        next if opt_def[:desc] !~ /and quit$/

        buf << "complete -c nanoc -n '__fish_use_subcommand'"
        buf << " -s #{quote opt_def[:short]}" if opt_def[:short]
        buf << " -l #{quote opt_def[:long]}" if opt_def[:long]
        buf << " -d #{quote opt_def[:desc]}"
        buf << "\n"
      end
      buf << "\n"

      # common options
      # FIXME: insert -x if necessary
      buf << "# common options\n"
      root_cmd.option_definitions.each do |opt_def|
        next if opt_def[:desc] =~ /and quit$/

        buf << "complete -c nanoc -n 'not __fish_use_subcommand'"
        buf << " -s #{quote opt_def[:short]}" if opt_def[:short]
        buf << " -l #{quote opt_def[:long]}" if opt_def[:long]
        buf << " -d #{quote opt_def[:desc]}"
        buf << "\n"
      end
      buf << "\n"

      # subcommands
      buf << "# subcommands\n"
      root_cmd.subcommands.each do |cmd|
        buf << "complete -c nanoc -n '__fish_use_subcommand' -xa "
        buf << quote(cmd.name)
        buf << " -d " << quote(cmd.summary)
        buf << "\n"
      end
      buf << "\n"

      # subcommand details
      root_cmd.subcommands.each do |cmd|
        buf << "# subcommand: #{cmd.name}\n"
        cmd.option_definitions.sort_by { |h| h[:short] || h[:long] }.each do |opt_def|
          # FIXME: insert -x if necessary
          buf << "complete -c nanoc -n 'contains #{quote cmd.name} (commandline -poc)'"
          buf << " -s #{quote opt_def[:short]}" if opt_def[:short]
          buf << " -l #{quote opt_def[:long]}" if opt_def[:long]
          buf << " -d #{quote opt_def[:desc]}"
          buf << "\n"
        end
        buf << "\n"
      end

      # # subcommand: help
      # complete -c nanoc -n 'contains help (commandline -poc)' -xa '\
      #   compile\t"'(_ "compile desc here")'" \
      #   help\t"'(_ "help desc here")'" \
      #   create-site\t"'(_ "create-site desc here")'" \
      #   check\t"'(_ "check desc here")'" \
      #   '

      buf
    end
    module_function :generate

    private

    def quote(s)
      '"' + escape(s) + '"'
    end
    module_function :quote

    def escape(s)
      s.gsub('\\', '\\\\').gsub('"', '\\"')
    end
    module_function :escape
  end
end

# # common options
# complete -c nanoc -n 'not __fish_use_subcommand' -s C -l no-color -d 'disable color' -x
# complete -c nanoc -n 'not __fish_use_subcommand' -s V -l verbose -d 'make output more detailed' -x
#
# # subcommand: check
# complete -c nanoc -n 'contains check (commandline -poc)' -s L -l list -d "list all checks" -x
# complete -c nanoc -n 'contains check (commandline -poc)' -s a -l all -d "run all checks" -x
# complete -c nanoc -n 'contains check (commandline -poc)' -s d -l deploy -d "run checks for deployment" -x
#
# # subcommand: help
# complete -c nanoc -n 'contains help (commandline -poc)' -xa '\
#   compile\t"'(_ "compile desc here")'" \
#   help\t"'(_ "help desc here")'" \
#   create-site\t"'(_ "create-site desc here")'" \
#   check\t"'(_ "check desc here")'" \
#   '

# encoding: utf-8

module Nanoc::Extra::Checking::Checks

  class Stale < ::Nanoc::Extra::Checking::Check

    identifier :stale

    def run
      item_rep_paths = self.item_rep_paths

      self.output_filenames.each do |f|
        next if self.pruner.filename_excluded?(f)
        if !item_rep_paths.include?(f)
          self.add_issue(
            "file without matching item",
            :subject  => f)
        end
      end
    end

  protected

    def item_rep_paths
      reps = @site.items.flat_map { |i| i.reps }
      reps.flat_map { |r| r.paths_without_snapshot }.map { |r| File.join(@site.config[:output_dir], r) }
    end

    def pruner
      exclude_config = @site.config.fetch(:prune, {}).fetch(:exclude, [])
      @pruner ||= Nanoc::Extra::Pruner.new(@site, :exclude => exclude_config)
    end

  end

end

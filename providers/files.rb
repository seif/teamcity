#
# Author:: Paul Morton (<larder-project@biaprotect.com>)
# Cookbook Name:: teamcity
#
# Copyright 2011, Paul Morton
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Teamcity::Helper

action :download do
  # So that we can refer to these within the sub-run-context block.
  cached_new_resource = new_resource
  cached_current_resource = current_resource

  # Setup a sub-run-context.
  sub_run_context = @run_context.dup
  sub_run_context.resource_collection = Chef::ResourceCollection.new

  # Declare sub-resources within the sub-run-context. Since they are declared here,
  # they do not pollute the parent run-context.
  begin
    original_run_context, @run_context = @run_context, sub_run_context
    
    # Do the actual work for this action:
    initialize_connection(cached_new_resource.connection)
    download_files(cached_new_resource.files,cached_new_resource.destination)
  rescue => e
    # For some reason errors were not bubbling up unless caught and raised
    Chef::Log.fatal(e)
    raise
  ensure
    @run_context = original_run_context
  end

  # Converge the sub-run-context inside the provider action.
  # Make sure to mark the resource as updated-by-last-action if any sub-run-context
  # resources were updated (any actual actions taken against the system) during the
  # sub-run-context convergence.
  begin
    Chef::Runner.new(sub_run_context).converge
  ensure
    new_resource.updated_by_last_action(true)
  end
end
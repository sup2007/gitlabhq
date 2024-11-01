# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User deletes files', :js, feature_category: :source_code_management do
  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when an user has write access' do
    before do
      project.add_maintainer(user)
      visit(project_tree_path_root_ref)
      wait_for_requests
    end

    it 'deletes the file', :js do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Delete')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      expect(page).to have_current_path(project_tree_path(project, 'master/'), ignore_query: true)
      expect(page).not_to have_content('.gitignore')
    end
  end

  context 'when an user does not have write access', :js do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
      wait_for_requests
    end

    it 'deletes the file in a forked project', :js, :sidekiq_might_not_need_inline do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Delete')

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')

      expect(page).to have_content(fork_message)

      click_on('Delete')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      fork = user.fork_of(project2.reload)

      expect(page).to have_current_path(project_new_merge_request_path(fork), ignore_query: true)
      expect(page).to have_content('New commit message')
    end
  end
end

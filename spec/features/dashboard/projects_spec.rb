require 'spec_helper'

RSpec.describe 'Dashboard Projects', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: "awesome stuff") }
  let(:project2) { create(:project, :public, name: 'Community project') }

  before do
    project.team << [user, :developer]
    gitlab_sign_in(user)
  end

  it 'shows the project the user in a member of in the list' do
    visit dashboard_projects_path
    expect(page).to have_content('awesome stuff')
  end

  context 'when last_repository_updated_at, last_activity_at and update_at are present' do
    it 'shows the last_repository_updated_at attribute as the update date' do
      project.update_attributes!(last_repository_updated_at: Time.now, last_activity_at: 1.hour.ago)

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.last_repository_updated_at.getutc.iso8601}']")
    end
  end

  context 'when last_repository_updated_at and last_activity_at are missing' do
    it 'shows the updated_at attribute as the update date' do
      project.update_attributes!(last_repository_updated_at: nil, last_activity_at: nil)
      project.touch

      visit dashboard_projects_path

      expect(page).to have_xpath("//time[@datetime='#{project.updated_at.getutc.iso8601}']")
    end
  end

  context 'when on Starred projects tab' do
    it 'shows only starred projects' do
      user.toggle_star(project2)

      visit(starred_dashboard_projects_path)

      expect(page).not_to have_content(project.name)
      expect(page).to have_content(project2.name)
    end
  end

  describe "with a pipeline", redis: true do
    let!(:pipeline) {  create(:ci_pipeline, project: project, sha: project.commit.sha) }

    before do
      # Since the cache isn't updated when a new pipeline is created
      # we need the pipeline to advance in the pipeline since the cache was created
      # by visiting the login page.
      pipeline.succeed
    end

    it 'shows that the last pipeline passed' do
      visit dashboard_projects_path

      expect(page).to have_xpath("//a[@href='#{pipelines_namespace_project_commit_path(project.namespace, project, project.commit)}']")
    end
  end

  it_behaves_like "an autodiscoverable RSS feed with current_user's RSS token"
end

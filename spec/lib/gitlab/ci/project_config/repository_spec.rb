# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProjectConfig::Repository, feature_category: :continuous_integration do
  let(:files) { { 'README.md' => 'hello' } }
  let(:project) { create(:project, :custom_repo, files: files) }
  let(:sha) { project.repository.head_commit.sha }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  subject(:config) { described_class.new(project, sha, nil, nil, nil, pipeline) }

  describe '#content' do
    subject(:content) { config.content }

    context 'when file is in repository' do
      let(:config_content_result) do
        <<~CICONFIG
        ---
        include:
        - local: ".gitlab-ci.yml"
        CICONFIG
      end

      let(:files) { { '.gitlab-ci.yml' => 'content' } }

      it { is_expected.to eq(config_content_result) }
    end

    context 'when file is not in repository' do
      it { is_expected.to be_nil }
    end

    context 'when Gitaly raises error' do
      before do
        allow(project.repository).to receive(:gitlab_ci_yml_for).and_raise(GRPC::Internal)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#source' do
    subject { config.source }

    it { is_expected.to eq(:repository_source) }
  end

  describe '#internal_include_prepended?' do
    subject { config.internal_include_prepended? }

    it { is_expected.to eq(true) }
  end

  describe '#url' do
    subject { config.url }

    it { is_expected.to eq("#{Settings.gitlab.base_url}/#{project.full_path}/-/blob/#{sha}/.gitlab-ci.yml") }
  end
end

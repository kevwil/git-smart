require "#{__dir__}/spec_helper"

require 'fileutils'

describe 'smart-pull' do
  def local_dir
    "#{WORKING_DIR}/local"
  end

  def remote_dir
    "#{WORKING_DIR}/remote"
  end

  before :each do
    %x[
      cd #{WORKING_DIR}
        mkdir remote
        cd remote
          git init
          git config --local user.name 'Maxwell Smart'
          git config --local user.email 'agent86@control.gov'
          git config --local core.pager 'cat'
          echo 'hurr durr' > README
          mkdir lib
          echo 'puts "pro hax"' > lib/codes.rb
          git add .
          git commit -m 'first'
        cd ..
        git clone remote/.git local
        cd local
          git config --local user.name 'Agent 99'
          git config --local user.email 'agent99@control.gov'
          git config --local core.pager 'cat'
          git config --global protocol.file.allow always
    ]
  end

  it "should tell us there's nothing to do" do
    out = run_command(local_dir, 'smart-pull')
    expect(out).to report('Executing: git fetch origin')
    expect(out).to report("Neither your local branch 'main', nor the remote branch 'origin/main' have moved on.")
    expect(out).to report('Already up-to-date')
  end

  context 'with only local changes' do
    before :each do
      %x[
        cd #{local_dir}
          echo 'moar things!' >> README
          echo 'puts "moar code!"' >> lib/moar.rb
          git add .
          git commit -m 'moar'
      ]
    end

    it 'should report that no remote changes were found' do
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Executing: git fetch origin')
      expect(out).to report("Remote branch 'origin/main' has not moved on.")
      expect(out).to report("You have 1 new commit on 'main'.")
      expect(out).to report('Already up-to-date')
    end
  end

  context 'with only remote changes' do
    before :each do
      %x[
        cd #{remote_dir}
          echo 'changed on the server!' >> README
          git add .
          git commit -m 'upstream changes'
      ]
    end

    it 'should fast-forward' do
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Executing: git fetch origin')
      expect(out).to report(%r{main +-> +origin/main})
      expect(out).to report("There is 1 new commit on 'origin/main'.")
      expect(out).to report("Local branch 'main' has not moved on. Fast-forwarding.")
      expect(out).to report('Executing: git merge --ff-only origin/main')
      expect(out).to report(/Updating [^.]+..[^.]+/)
      expect(out).to report(/1 files? changed, 1 insertions?\(\+\)(, 0 deletions\(-\))?$/)
    end

    it 'should not stash before fast-forwarding if untracked files are present' do
      %x[
        cd #{local_dir}
          echo "i am nub" > noob
      ]
      expect(local_dir).to have_git_status({ untracked: ['noob'] })
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Executing: git merge --ff-only origin/main')
      expect(out).to report(/1 files? changed, 1 insertions?\(\+\)(, 0 deletions\(-\))?$/)
      expect(local_dir).to have_git_status({ untracked: ['noob'] })
    end

    it 'should stash, fast forward, pop if there are local changes' do
      %x[
        cd #{local_dir}
          echo "i am nub" > noob
          echo "puts 'moar codes too!'" >> lib/codes.rb
          git add noob
      ]
      expect(local_dir).to have_git_status({ added: ['noob'], modified: ['lib/codes.rb'] })
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Working directory dirty. Stashing...')
      expect(out).to report('Executing: git stash')
      expect(out).to report('Executing: git merge --ff-only origin/main')
      expect(out).to report(/1 files? changed, 1 insertions?\(\+\)(, 0 deletions\(-\))?$/)
      expect(out).to report('Reapplying local changes...')
      expect(out).to report('Executing: git stash pop')
      expect(local_dir).to have_git_status({ added: ['noob'], modified: ['lib/codes.rb'] })
    end
  end

  context 'with diverged branches' do
    before :each do
      %x[
        cd #{remote_dir}
          echo 'changed on the server!' >> README
          git add .
          git commit -m 'upstream changes'

        cd #{local_dir}
          echo "puts 'moar codes too!'" >> lib/codes.rb
          git add .
          git commit -m 'local changes'
      ]
    end

    it 'should rebase' do
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Executing: git fetch origin')
      expect(out).to report(%r{main +-> +origin/main})
      expect(out).to report("There is 1 new commit on 'origin/main'.")
      expect(out).to report("You have 1 new commit on 'main'.")
      expect(out).to report("Both local and remote branches have moved on. Branch 'main' needs to be rebased onto 'origin/main'")
      expect(out).to report('Executing: git rebase --rebase-merges origin/main')
      expect(out).to report('Successfully rebased and updated refs/heads/main.')
      expect(local_dir).to have_last_few_commits(['local changes', 'upstream changes', 'first'])
    end

    it 'should not stash before rebasing if untracked files are present' do
      %x[
        cd #{local_dir}
          echo "i am nub" > noob
      ]
      expect(local_dir).to have_git_status({ untracked: ['noob'] })
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Executing: git rebase --rebase-merges origin/main')
      expect(out).to report('Successfully rebased and updated refs/heads/main.')
      expect(local_dir).to have_git_status({ untracked: ['noob'] })
      expect(local_dir).to have_last_few_commits(['local changes', 'upstream changes', 'first'])
    end

    it 'should stash, rebase, pop if there are local uncommitted changes' do
      %x[
        cd #{local_dir}
          echo "i am nub" > noob
          echo "puts 'moar codes too!'" >> lib/codes.rb
          git add noob
      ]
      expect(local_dir).to have_git_status({ added: ['noob'], modified: ['lib/codes.rb'] })
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Working directory dirty. Stashing...')
      expect(out).to report('Executing: git stash')
      expect(out).to report('Executing: git rebase --rebase-merges origin/main')
      expect(out).to report('Successfully rebased and updated refs/heads/main.')
      expect(local_dir).to have_git_status({ added: ['noob'], modified: ['lib/codes.rb'] })
      expect(local_dir).to have_last_few_commits(['local changes', 'upstream changes', 'first'])
    end
  end

  context 'with a submodule' do
    before do
      %x[
      cd #{WORKING_DIR}
        mkdir submodule
        cd submodule
          git init
          git config --local user.name 'The Chief'
          git config --local user.email 'agentq@control.gov'
          git config --local core.pager 'cat'
          echo 'Unusual, but effective.' > README
          git add .
          git commit -m 'first'
        cd ../local
          git submodule add "${PWD}/../submodule/.git" submodule
          git commit -am 'Add submodule'
      ]
    end
    let(:submodule_dir) { "#{local_dir}/submodule" }

    it 'can smart-pull the repo containing the submodule' do
      out = run_command(local_dir, 'smart-pull')
      expect(out).to report('Executing: git fetch origin')
      expect(out).to report("Remote branch 'origin/main' has not moved on.")
      expect(out).to report("You have 1 new commit on 'main'.")
    end

    it 'can smart-pull the submodule' do
      out = run_command(submodule_dir, 'smart-pull')
      expect(out).to report('Executing: git fetch origin')
      expect(out).to report("Neither your local branch 'main', nor the remote branch 'origin/main' have moved on.")
      expect(out).to report('Already up-to-date')
    end
  end

  context 'outside of a repo' do
    it 'should report a meaningful error' do
      Dir.mktmpdir do |non_repo_dir|
        out = run_command(non_repo_dir, 'smart-pull')
        expect(out).to report 'You need to run this from within a Git directory'
        expect(out).to report 'Current working directory: '
        expect(out).to report 'Expected .git directory: '
      end
    end
  end
end

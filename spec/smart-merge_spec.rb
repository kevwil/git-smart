require "#{__dir__}/spec_helper"

require 'fileutils'

describe 'smart-merge' do
  def local_dir
    "#{WORKING_DIR}/local"
  end

  before :each do
    %x[
      cd #{WORKING_DIR}
        mkdir local
        cd local
          git init
          git config --local user.name 'Maxwell Smart'
          git config --local user.email 'agent86@control.gov'
          git config --local core.pager 'cat'
          echo 'hurr durr' > README
          mkdir lib
          echo 'puts "pro hax"' > lib/codes.rb
          git add .
          git commit -m 'first'
    ]
  end

  it 'should require an argument' do
    out = run_command(local_dir, 'smart-merge')
    expect(out).to report('Usage: git smart-merge ref')
  end

  it 'should require a valid branch' do
    out = run_command(local_dir, 'smart-merge', 'foo')
    expect(out).to report("Branch to merge 'foo' not recognised by git!")
  end

  it "should report nothing to do if the branch hasn't moved on" do
    %x[
      cd #{local_dir}
      git branch unmoved
    ]
    out = run_command(local_dir, 'smart-merge', 'unmoved')
    expect(out).to report("Branch 'unmoved' has no new commits. Nothing to merge in.")
    expect(out).to report('Already up-to-date.')
  end

  context 'with local changes to newbranch' do
    before :each do
      %x[
        cd #{local_dir}
          git checkout -b newbranch 2> /dev/null
          echo 'moar things!' >> README
          echo 'puts "moar code!"' >> lib/moar.rb
          git add .
          git commit -m 'moar'

          git checkout main 2> /dev/null
      ]
    end

    it 'should merge --no-ff, despite the branch being fast-forwardable' do
      out = run_command(local_dir, 'smart-merge', 'newbranch')
      expect(out).to report("Branch 'newbranch' has diverged by 1 commit. Merging in.")
      expect(out).to report("* Branch 'main' has not moved on since 'newbranch' diverged. Running with --no-ff anyway, since a fast-forward is unexpected behaviour.")
      expect(out).to report('Executing: git merge --no-ff newbranch')
      expect(out).to report(/2 files changed, 2 insertions\(\+\)(, 0 deletions\(-\))?$/)
      expect(out).to report(/All good\. Created merge commit \w{7}\./)
    end

    context 'and changes on master' do
      before :each do
        %x[
          cd #{local_dir}
            echo "puts 'moar codes too!'" >> lib/codes.rb
            git add .
            git commit -m 'changes on main'
        ]
      end

      it 'should merge in ok' do
        out = run_command(local_dir, 'smart-merge', 'newbranch')
        expect(out).to report("Branch 'newbranch' has diverged by 1 commit. Merging in.")
        expect(out).to report("Branch 'main' has 1 new commit since 'newbranch' diverged.")
        expect(out).to report('Executing: git merge --no-ff newbranch')
        expect(out).to report(/2 files changed, 2 insertions\(\+\)(, 0 deletions\(-\))?$/)
        expect(out).to report(/All good\. Created merge commit \w{7}\./)
      end

      it 'should stash then merge if working tree is dirty' do
        %x[
          cd #{local_dir}
            echo "i am nub" > noob
            echo "puts 'moar codes too!'" >> lib/codes.rb
            git add noob
        ]
        out = run_command(local_dir, 'smart-merge', 'newbranch')
        expect(out).to report('Executing: git stash')
        expect(out).to report('Executing: git merge --no-ff newbranch')
        expect(out).to report(/2 files changed, 2 insertions\(\+\)(, 0 deletions\(-\))?$/)
        expect(out).to report('Reapplying local changes...')
        expect(out).to report('Executing: git stash pop')
        expect(out).to report(/All good\. Created merge commit \w{7}\./)
      end
    end
  end
end

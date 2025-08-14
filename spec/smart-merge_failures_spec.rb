require "#{__dir__}/spec_helper"

require 'fileutils'

describe 'smart-merge with failures' do
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
      echo -e 'one\ntwo\nthree\nfour\n' > README
      mkdir lib
      echo 'puts "pro hax"' > lib/codes.rb
      git add .
      git commit -m 'first'
    ]
  end

  context 'with conflicting changes on main and newbranch' do
    before :each do
      %x[
        cd #{local_dir}
        git checkout -b newbranch 2> /dev/null
        echo 'one\nnewbranch changes\nfour\n' > README
        git commit -am 'newbranch_commit'

        git checkout main 2> /dev/null

        echo 'one\nmain changes\nfour\n' > README
        git commit -am 'main_commit'
      ]
    end

    it 'should report the failure and give instructions to the user' do
      out = run_command(local_dir, 'smart-merge', 'newbranch')
      expect(local_dir).to have_git_status(conflicted: ['README'])
      expect(out).not_to report('All good')
      expect(out).to report('Executing: git merge --no-ff newbranch')
      expect(out).to report('CONFLICT (content): Merge conflict in README')
      expect(out).to report('Automatic merge failed; fix conflicts and then commit the result.')
    end
  end
end

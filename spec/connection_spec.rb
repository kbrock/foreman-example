require 'spec_helper'

describe ManageiqForeman::Connection do
  subject(:connection) { described_class.new(FOREMAN) }

  describe "#host" do
    context "with 2 hosts" do
      let(:results) { connection.hosts("per_page" => 2).results }

      it "fetches 2 hosts" do
        VCR.use_cassette("#{described_class.name}") do
          expect(results.size).to eq(2)
        end
      end

      it "has keys we need" do
        VCR.use_cassette("#{described_class.name}") do
          expect(results.first.keys).to include(*%w(id name ip mac hostgroup_id uuid build
                                                    enabled operatingsystem_id domain_id ptable_id medium_id))
        end
      end
    end

    context "with all hosts", :vcr => RECORD do
      let(:results) { connection.all(:hosts) }

      it "paginates" do
        expect(results.size).to eq(31)
      end
    end

  end

  describe "#all(:hosts)" do
  end

  def with_vcr
    VCR.use_cassette("#{described_class.name}") do
      yield
    end
  end
end

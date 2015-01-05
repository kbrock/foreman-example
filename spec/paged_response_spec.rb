require 'spec_helper'

describe ManageiqForeman::PagedResponse do
  describe "#initializer" do
    context "with index hash" do
    end

    context "with array" do
    end

    context "with show hash" do
      subject(:paged_response) do
        described_class.new({"id" => "the id"})
      end

      it "collects the show hash" do
        expect(paged_response.size).to eq(1)
        expect(paged_response.first).to eq({"id" => "the id"})
      end
    end
  end
end

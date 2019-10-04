RSpec.describe Lowkiq::Utils do
  describe "Array" do
    it "#in_transposed_groups" do
      groups = Lowkiq::Utils::Array.new((0...10)).in_transposed_groups(3)

      expect(groups).to eq([
                             [0,3,6,9],
                             [1,4,7],
                             [2,5,8],
                           ])
    end
  end
end

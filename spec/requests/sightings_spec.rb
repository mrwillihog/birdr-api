require "rails_helper"

RSpec.describe "Sightings", type: :request do
  describe "POST /sightings" do
    context "unauthenticated users" do
      it "returns a 401" do
        post "/sightings", params: {}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "authenticated users" do
      let (:user) { FactoryGirl.create :user }
      let (:bird) { FactoryGirl.create :bird }

      it "creates the sighting" do
        expect {
          post "/sightings", params: json_params({ bird_id: bird.id }), headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
        }.to change { user.sightings.count }.from(0).to(1)
        expect(response).to have_http_status(:created)
      end
      it "returns the sighting in the response" do
        post "/sightings", params: json_params({ bird_id: bird.id }), headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }

        expect(response).to have_http_status(:created)

        expect(json_body[:id]).to eq Sighting.last.id
        expect(json_body[:bird][:id]).to eq bird.id
        expect(json_body[:user][:id]).to eq user.id
      end
      context "invalid requests" do
        it "returns a 422 when missing a bird_id" do
          post "/sightings", params: {}, headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
        it "returns a 422 when sent an invalid bird_id" do
          post "/sightings", params: json_params({ bird_id: 'no' }), headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
        it "returns a 422 for a duplicate bird_id" do
          post "/sightings", params: json_params({ bird_id: bird.id }), headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
          expect(response).to have_http_status(:created)

          post "/sightings", params: json_params({ bird_id: bird.id }), headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "DELETE /sightings/:id" do
    let (:user) { FactoryGirl.create :user }
    let (:bird) { FactoryGirl.create :bird }

    context "unauthenticated users" do
      it "returns a 401" do
        sighting = user.sightings.create bird_id: bird.id

        delete "/sightings/#{sighting.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "authenticated users" do
      it "returns a 401 when trying to delete another users sighting" do
        sighting = user.sightings.create bird_id: bird.id
        sneaky_user = FactoryGirl.create :user

        expect {
          delete "/sightings/#{sighting.id}", headers: { "Authorization": "Bearer #{token_for(sneaky_user)}", "Content-Type": "application/json" }
        }.to_not change { user.sightings.count }
        expect(response).to have_http_status(:unauthorized)
      end
      it "returns a 404 for an invalid sighting" do
        delete "/sightings/invalid", headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
        expect(response).to have_http_status(:not_found)
      end
      it "removes the sighting" do
        sighting = user.sightings.create bird_id: bird.id
        expect {
          delete "/sightings/#{sighting.id}", headers: { "Authorization": "Bearer #{token_for(user)}", "Content-Type": "application/json" }
        }.to change { user.sightings.count }.from(1).to(0)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end

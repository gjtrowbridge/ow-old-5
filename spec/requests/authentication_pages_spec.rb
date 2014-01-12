require 'spec_helper'

describe "Authentication" do
  subject { page }

  describe "index page" do
    describe "for non-signed-in users" do
      it { should_not have_link('Settings') }
      it { should_not have_link('Profile') }
      it { should_not have_link('Sign out') }
    end
  end

  describe "signin page" do
    before { visit signin_path }

    it { should have_content('Sign in') }
    it { should have_title('Sign in') }

  end

  describe "signin" do
    before { visit signin_path }

    describe "with invalid information" do
      before { click_button "Sign in"}

      it { should have_title("Sign in") }
      it { should have_error_message('Invalid') }
      describe "after visiting another page" do
        before { click_link "orangewalrus" }
        it { should_not have_selector('div.alert.alert-error') }
      end
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      before do
        valid_signin(user)
      end

      it { should have_title(user.display_name) }
      it { should have_link('Users',       href: users_path) }
      it { should have_link("Profile", href:user_path(user)) }
      it { should have_link("Sign out", href:signout_path) }
      it { should have_link("Settings", href: edit_user_path(user)) }
      it { should_not have_link("Sign in", href: signin_path) }

      describe "submitting a get request to the signin page" do
        before do
          visit signin_path
        end
        it { should have_content("Already signed in") }
      end

      describe "submitting a get request to the signup page" do
        before do
          #get signup_path
          visit signup_path
        end
        #specify { expect(response.body).not_to match(full_title('Sign up')) }
        #specify { expect(response).to redirect_to(root_url) }
        it { should have_content("Already signed in") }
      end

      describe "followed by signout" do
        before { click_link "Sign out"}
        it { should have_link('Sign in') }
      end
    end
  end

  describe "authorization" do
    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      describe "in the Users controller" do
        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_title('Sign in' ) }
        end

        describe "submitting to the update action" do
          before { patch user_path(user) }
          specify { expect(response).to redirect_to(signin_path) }
        end

        describe "when attempting to visit a protected page" do
          before do
            visit edit_user_path(user)
            fill_in "Email", with: user.email
            fill_in "Password", with: user.password
            click_button "Sign in"
          end
          describe "after signing in" do
            it "should render the desired protected page" do
              expect(page).to have_title("Edit User")
            end
          end
        end
        describe "visiting the user index" do
          before { visit users_path }
          it { should have_title('Sign in') }
        end
      end

      describe "in the Activities controller" do
        let(:activity) { FactoryGirl.create(:activity) }
        describe "submitting to the create action" do
          before { post activities_path }
          specify { expect(response).to redirect_to(signin_path) }
        end

        describe "submitting to the destroy action" do
          before { delete activity_path(activity) }
          specify { expect(response).to redirect_to(signin_path) }
        end

        describe "submitting to the update action" do
          before { patch activity_path(activity) }
          specify { expect(response).to redirect_to(signin_path) }
        end

        describe "visiting the edit activity page" do
          before { visit edit_activity_path(activity) }
          it { should have_title('Sign in') }
        end

        describe "visiting the activity index page" do
          before { visit activities_path }
          it { should have_title('Activity Index') }
        end
        describe "visiting the activity profile page" do
          before { visit activity_path(activity) }
          it { should have_title(activity.name) }
        end
      end
    end
    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com", display_name: "Wrong User") }
      before { valid_signin user, no_capybara: true }

      describe "submitting a GET request to the Users#edit action" do
        before { get edit_user_path(wrong_user) }
        specify { expect(response.body).not_to match(full_title('Edit user')) }
        specify { expect(response).to redirect_to(root_url) }
      end

      describe "submitting a PATCH request to the Users#update action" do
        before { patch user_path(wrong_user) }
        specify { expect(response).to redirect_to(root_url) }
      end

      describe "in the Activities controller" do
        let(:activity) { FactoryGirl.create(:activity, user_id: wrong_user.id) }

        describe "visiting another user's activity profile page" do
          before { visit activity_path(activity)}
          it { should_not have_link("Edit") }
        end

        describe "submitting a GET request to the Activities#edit action" do
          before { get edit_activity_path(activity) }
          specify { expect(response.body).not_to match(full_title('Edit Activity')) }
        end

        describe "submitting a PATCH request to the Activities#update action" do
          before { patch activity_path(activity) }
          specify { expect(response).to redirect_to(activity_path(activity)) }
        end
      end
    end

    describe "as non-admin user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:non_admin) { FactoryGirl.create(:user) }

      before { valid_signin non_admin, no_capybara: true }

      describe "submitting a DELETE request to the Users#destroy action" do
        before { delete user_path(user) }
        specify { expect(response).to redirect_to(root_url) }
      end
    end
  end
end

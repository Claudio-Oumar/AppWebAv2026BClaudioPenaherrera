using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;

using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Login : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
#if DEBUG
                // Credenciales de prueba creadas por el script BDD_PoliMusic.sql
                txtLogin.Text = "username1";
                txtPassword.Text = "12345678";
                txtPassword.Attributes.Add("value", txtPassword.Text);
                txtPassword.TextMode = TextBoxMode.Password;
#endif
                lblMessage.Text = string.Empty;
            }
        }

        protected void BtnLogin_Click(object sender, EventArgs e)
        {
            string login = txtLogin.Text.Trim();
            string password = txtPassword.Text;

            lblMessage.Text = string.Empty;

            if (string.IsNullOrEmpty(login) || string.IsNullOrEmpty(password))
            {
                lblMessage.Text = "Please, write a login/password.";
                return;
            }

            DataTable dtUser;
            try
            {
                string passwordHash = Util.Hash.GeneratePasswordHash(password);
                dtUser = new BLL.User(strConnString).AuthenticateUser(login, passwordHash);
            }
            catch (Exception)
            {
                lblMessage.Text = "Could not connect to the database. Please try again later.";
                return;
            }

            if (dtUser == null || dtUser.Rows.Count == 0)
            {
                lblMessage.Text = "Login/password incorrect, try again.";
                return;
            }

            Entities.User user = new Entities.User();
            user.ID = Convert.ToInt32(dtUser.Rows[0]["ID_USER"]);
            user.UserName = login;
            user.Photo = dtUser.Rows[0]["USER_PHOTO"].ToString();
            user.Email = dtUser.Rows[0]["EMAIL"].ToString();
            user.Birthday = dtUser.Rows[0]["BIRTHDAY"].ToString();
            user.UserType = Convert.ToInt32(dtUser.Rows[0]["USER_TYPE"]);

            if (user.UserType != Util.Constants.ID_USER_NORMAL &&
                user.UserType != Util.Constants.ID_USER_ADMIN)
            {
                lblMessage.Text = "Login/password incorrect, try again.";
                return;
            }

            Session[Util.Constants.USER] = user;
            FormsAuthentication.RedirectFromLoginPage(login, true);
        }

        protected void LinkButtonNewUser_Click(object sender, EventArgs e)
        {
            Response.Redirect("SignUp.aspx", true);
        }
    }

}
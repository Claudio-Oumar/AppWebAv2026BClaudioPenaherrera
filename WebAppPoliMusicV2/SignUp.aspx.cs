using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;

using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class SignUp : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnSumbit_Click(object sender, EventArgs e)
        {
            string messageValidations = string.Empty;
            string userName = txtUserName.Text.Trim();
            string password = txtPassword.Text;
            string confirmPassword = txtConfirmPassword.Text;
            string email = txtEmail.Text.Trim();
            string birthday = string.Empty;

            lblMessage.ForeColor = System.Drawing.Color.Red;

            if (txtBirthDate.Text.Trim() != string.Empty)
            {
                DateTime d;
                if (DateTime.TryParseExact(txtBirthDate.Text.Trim(), "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out d))
                {
                    // yyyyMMdd is unambiguous for SQL Server regardless of the login language.
                    birthday = d.ToString("yyyyMMdd");
                }
                else
                {
                    lblMessage.Text = "Birth date must have the format dd/MM/yyyy.";
                    return;
                }
            }

            Entities.User user = new Entities.User();
            user.UserName = userName;
            user.Email = email;
            user.Password = password;
            user.Birthday = birthday;
            user.UserType = Util.Constants.ID_USER_NORMAL;

            messageValidations = UserFieldsRequiredValidations(user);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }

            if (password != confirmPassword)
            {
                lblMessage.Text = "Password and confirm password do not match!";
                return;
            }

            string safeUserName = GetSafeFileName(userName);
            if (safeUserName.Length == 0)
            {
                lblMessage.Text = "Username is not valid!";
                return;
            }
            string newImageName = "user_" + safeUserName;

            string strImageFolder = ConfigurationManager.AppSettings["userPhotoPath"];
            string photoExtension = fupPhoto.HasFile
                ? Path.GetExtension(fupPhoto.FileName).ToLowerInvariant()
                : ".jpg";
            user.Photo = strImageFolder + newImageName + photoExtension;

            string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
            try
            {
                messageValidations = new BLL.User(strConnString).ValidationsDuplicated(user);
            }
            catch (Exception)
            {
                lblMessage.Text = "Could not connect to the database. Please try again later.";
                return;
            }

            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }

            if (fupPhoto.HasFile)
            {
                messageValidations = new FileManagement().SaveImageOnServer(fupPhoto, strImageFolder, newImageName);
            }
            else
            {
                messageValidations = new FileManagement().SaveDefaultImageOnServer(strImageFolder, newImageName);
            }

            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }

            try
            {
                user.Password = Util.Hash.GeneratePasswordHash(password);
                new BLL.User(strConnString).Save(user);
            }
            catch (Exception)
            {
                // Do not leave an orphan image if the database insert fails.
                try
                {
                    string savedImage = Server.MapPath(user.Photo);
                    if (File.Exists(savedImage))
                    {
                        File.Delete(savedImage);
                    }
                }
                catch (Exception)
                {
                    // Ignore cleanup errors; the registration message is the important one.
                }

                lblMessage.Text = "User could not be registered. Please try again later.";
                return;
            }

            lblMessage.ForeColor = System.Drawing.Color.Green;
            lblMessage.Text = "User registered successfully!. Please go to login page.";
        }

        public string UserFieldsRequiredValidations(Entities.User user)
        {
            if (string.IsNullOrEmpty(user.UserName))
            {
                return "Username is required!";
            }
            if (user.UserName.Length > 50)
            {
                return "Username must have 50 characters or less!";
            }
            if (string.IsNullOrEmpty(user.Email))
            {
                return "Email is required!";
            }
            if (user.Email.Length > 50)
            {
                return "Email must have 50 characters or less!";
            }
            if (string.IsNullOrEmpty(user.Password))
            {
                return "Password is required!";
            }
            if (!IsValidEmail(user.Email))
            {
                return "Email is not valid!";
            }
            return string.Empty;
        }

        public static bool IsValidEmail(string email)
        {
            if (string.IsNullOrEmpty(email) || email.Replace(" ", "") == string.Empty)
                return false;

            try
            {
                // Normalize the domain
                email = Regex.Replace(email, @"(@)(.+)$", DomainMapper, RegexOptions.None);
            }
            catch (Exception)
            {
                return false;
            }
            try
            {
                return Regex.IsMatch(email,
                    @"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                    RegexOptions.IgnoreCase);
            }
            catch (Exception)
            {
                return false;
            }
        }

        private static string DomainMapper(Match match)
        {
            // Use IdnMapping class to convert Unicode domain names.
            IdnMapping idn = new IdnMapping();

            // Pull out and process domain name (throws ArgumentException on invalid)
            string domainName = idn.GetAscii(match.Groups[2].Value);

            return match.Groups[1].Value + domainName;
        }

        /// <summary>
        /// Removes spaces and characters that are not valid in a Windows file name.
        /// </summary>
        private static string GetSafeFileName(string value)
        {
            string safeValue = value.Replace(" ", string.Empty);

            foreach (char invalidChar in Path.GetInvalidFileNameChars())
            {
                safeValue = safeValue.Replace(invalidChar.ToString(), string.Empty);
            }

            return safeValue;
        }
    }
}

using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        private string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                Entities.User user = Session[Util.Constants.USER] as Entities.User;
                if (user == null)
                {
                    Response.Redirect("~/Login.aspx", true);
                    return;
                }

                lblUsuario.Text = Server.HtmlEncode(user.UserName);
                LoadSongs();
            }
        }

        private void LoadSongs()
        {
            try
            {
                DataTable dtSongs = new BLL.Song(strConnString).Read();
                gvCanciones.DataSource = dtSongs;
                gvCanciones.DataBind();
                lblError.Text = string.Empty;
            }
            catch (Exception)
            {
                lblError.Text = "No se pudo cargar la lista de canciones. Verifique la conexión a la base de datos.";
            }
        }

        protected string GetAudioUrl(object songPath)
        {
            if (songPath == null || songPath == DBNull.Value)
            {
                return string.Empty;
            }

            string ruta = songPath.ToString().Trim();
            string fileName = Path.GetFileName(ruta.Replace('/', '\\'));

            if (string.IsNullOrEmpty(fileName) ||
                !fileName.EndsWith(".mp3", StringComparison.OrdinalIgnoreCase))
            {
                return string.Empty;
            }

            return ResolveUrl("~/SongFiles/" + Uri.EscapeDataString(fileName));
        }
    }
}

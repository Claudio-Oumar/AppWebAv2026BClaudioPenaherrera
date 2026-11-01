
<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="Song.aspx.cs"
    Inherits="WebAppPoliMusicV2.Song" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0" />

    <title>Mis canciones | PoliMusic</title>

    <style type="text/css">

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #0b0c15;
            color: #ffffff;
        }

        /* ENCABEZADO */

        .navbar {
            background: #11111e;
            border-bottom: 1px solid #292638;
            padding: 22px 5%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 20px;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 25px;
            font-weight: 800;
        }

        .brand-icon {
            width: 45px;
            height: 45px;
            border-radius: 13px;
            background: linear-gradient(
                135deg, #a855f7, #6d28d9
            );
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 27px;
        }

        .brand span {
            color: #b990ff;
        }

        .logout-link {
            color: #c4a2ff;
            font-size: 14px;
            font-weight: 600;
            text-decoration: none;
            padding: 11px 18px;
            background: rgba(168, 85, 247, 0.1);
            border: 1px solid rgba(168, 85, 247, 0.2);
            border-radius: 10px;
        }

        .logout-link:hover {
            background: #a855f7;
            color: white;
        }

        /* CONTENIDO */

        .container {
            max-width: 1300px;
            margin: 0 auto;
            padding: 45px 25px;
        }

        .welcome-card {
            background: linear-gradient(
                115deg, #281745, #4d2682
            );
            border-radius: 20px;
            padding: 35px 40px;
            margin-bottom: 40px;
            position: relative;
            overflow: hidden;
        }

        .welcome-card::after {
            content: "♫";
            position: absolute;
            right: 45px;
            top: 0;
            font-size: 180px;
            opacity: 0.12;
            pointer-events: none;
        }

        .welcome-tag {
            color: #dbbcff;
            font-size: 12px;
            letter-spacing: 2px;
            font-weight: 700;
        }

        .welcome-title {
            font-size: 34px;
            font-weight: 800;
            margin: 16px 0 10px;
            letter-spacing: -1px;
            overflow-wrap: anywhere;
        }

        .username {
            color: #dabaff;
        }

        .welcome-description {
            color: #d0bde9;
            font-size: 15px;
            line-height: 1.7;
            margin: 0;
        }

        /* SECCIÓN DE CANCIONES */

        .section-header {
            margin-bottom: 25px;
        }

        .section-title {
            font-size: 26px;
            font-weight: 750;
            margin: 0 0 10px;
        }

        .section-title span {
            color: #b990ff;
        }

        .section-description {
            font-size: 14px;
            color: #9694a9;
            margin: 0;
        }

        /* TABLA */

        .table-container {
            background: #171724;
            border: 1px solid #302d42;
            border-radius: 17px;
            overflow-x: auto;
        }

        .song-table {
            width: 100%;
            min-width: 780px;
            border-collapse: collapse;
        }

        .song-table th {
            background: #211c34;
            color: #c8b1eb;
            padding: 20px 17px;
            font-size: 13px;
            font-weight: 700;
            text-align: left;
            border-bottom: 1px solid #39314c;
        }

        .song-table td {
            padding: 18px 17px;
            border-bottom: 1px solid #2a283a;
            color: #e2dfeb;
            font-size: 14px;
            vertical-align: middle;
            overflow-wrap: anywhere;
        }

        .song-table tr:last-child td {
            border-bottom: none;
        }

        .song-table tr:hover td {
            background: #242037;
        }

        .song-table td:first-child {
            color: #b990ff;
            font-weight: 700;
        }

        .song-table td:nth-child(2) {
            color: #ffffff;
            font-weight: 650;
        }

        .song-table td:nth-child(3) {
            color: #9793ad;
            font-size: 12px;
            overflow-wrap: anywhere;
        }

        .song-table td:nth-child(4) {
            color: #c4a2ff;
        }

        /* REPRODUCTOR */

        .song-player {
            width: 230px;
            max-width: 100%;
            height: 42px;
            display: block;
            border-radius: 25px;
        }

        /* ERRORES */

        .error {
            display: block;
            color: #fda4af;
            font-size: 14px;
        }

        .error:not(:empty) {
            background: rgba(239, 68, 68, 0.08);
            border: 1px solid rgba(239, 68, 68, 0.2);
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 20px;
        }

        /* PIE DE PÁGINA */

        .footer {
            text-align: center;
            padding: 35px 20px;
            color: #737087;
            font-size: 12px;
        }

        /* RESPONSIVE */

        @media (max-width: 768px) {
            .container {
                padding: 25px 15px;
            }

            .navbar {
                padding: 18px 20px;
            }

            .brand {
                font-size: 21px;
            }

            .welcome-card {
                padding: 28px 22px;
            }

            .welcome-title {
                font-size: 27px;
            }

            .welcome-card::after {
                right: 0;
                font-size: 120px;
            }

            .section-title {
                font-size: 23px;
            }

            .logout-link {
                padding: 10px;
                font-size: 12px;
            }
        }

    </style>
</head>

<body>
    <form id="form1" runat="server">

        <!-- BARRA SUPERIOR -->
        <header class="navbar">

            <div class="brand">
                <div class="brand-icon">♫</div>
                <div>Poli<span>Music</span></div>
            </div>

            <asp:HyperLink
                ID="lnkSalir"
                runat="server"
                CssClass="logout-link"
                NavigateUrl="~/Logout.aspx">
                Cerrar sesión
            </asp:HyperLink>

        </header>

        <main class="container">

            <!-- BIENVENIDA -->
            <section class="welcome-card">

                <div class="welcome-tag">
                    ♪ TU ESPACIO MUSICAL
                </div>

                <h1 class="welcome-title">

                    Bienvenido,

                    <span class="username">
                        <asp:Label
                            ID="lblUsuario"
                            runat="server">
                        </asp:Label>
                    </span>

                </h1>

                <p class="welcome-description">
                    Disfruta de tus canciones favoritas
                    en PoliMusic. Encuentra tu música
                    y comienza a escuchar.
                </p>

            </section>

            <!-- LISTADO -->
            <section>

                <div class="section-header">

                    <h2 class="section-title">
                        ♫ Lista de <span>canciones</span>
                    </h2>

                    <p class="section-description">
                        Explora las canciones disponibles
                        en tu biblioteca musical.
                    </p>

                </div>

                <!-- ERROR -->
                <asp:Label
                    ID="lblError"
                    runat="server"
                    CssClass="error">
                </asp:Label>

                <!-- TABLA DE CANCIONES -->
                <div class="table-container">

                    <asp:GridView
                        ID="gvCanciones"
                        runat="server"
                        AutoGenerateColumns="False"
                        CssClass="song-table"
                        GridLines="None"
                        CellPadding="0"
                        EmptyDataText="No hay canciones registradas.">

                        <Columns>

                            
                            <asp:BoundField
                                DataField="ID_SONG"
                                HeaderText="ID Canción" />

                          
                            <asp:BoundField
                                DataField="SONG_NAME"
                                HeaderText="Nombre" />

                        
                            <asp:BoundField
                                DataField="SONG_PATH"
                                HeaderText="Ruta" />

                        
                            <asp:BoundField
                                DataField="PLAYS"
                                HeaderText="Reproducciones" />

                        
                            <asp:TemplateField
                                HeaderText="Reproducir">

                                <ItemTemplate>

                                    <audio
                                        class="song-player"
                                        controls="controls"
                                        preload="none">

                                        <source
                                            src='<%# GetAudioUrl(
                                                Eval("SONG_PATH")
                                            ) %>'
                                            type="audio/mpeg" />

                                        Tu navegador no
                                        soporta audio.

                                    </audio>

                                </ItemTemplate>

                            </asp:TemplateField>

                        </Columns>

                    </asp:GridView>

                </div>

            </section>

        </main>

        <footer class="footer">
            © 2026 PoliMusic · Aplicaciones Web Avanzadas
        </footer>

    </form>
</body>
</html>
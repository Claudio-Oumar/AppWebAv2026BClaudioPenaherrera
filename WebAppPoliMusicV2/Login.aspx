
<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="Login.aspx.cs"
    Inherits="WebAppPoliMusicV2.Login" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0" />

    <title>Iniciar sesión | PoliMusic</title>

    <style type="text/css">
        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            min-height: 100vh;
            font-family: 'Segoe UI', Arial, sans-serif;
            background: #080912;
            color: #ffffff;
        }

        .login-page {
            min-height: 100vh;
            display: grid;
            grid-template-columns: 1fr 1fr;
        }

        /* PANEL IZQUIERDO */

        .hero {
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 48px 9%;
            background:
                radial-gradient(
                    ellipse at 50% 55%,
                    #46219a 0%,
                    #211344 40%,
                    #100e22 85%
                );
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 13px;
            font-size: 25px;
            font-weight: 800;
            letter-spacing: -1px;
            position: relative;
            z-index: 2;
        }

        .brand-icon {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 45px;
            height: 45px;
            border-radius: 14px;
            background: linear-gradient(
                135deg, #a855f7, #6d28d9
            );
            font-size: 27px;
        }

        .brand span {
            color: #b990ff;
        }

        .hero-content {
            position: relative;
            z-index: 2;
            max-width: 560px;
        }

        .eyebrow {
            color: #d8b4fe;
            font-size: 12px;
            font-weight: 700;
            letter-spacing: 3px;
            text-transform: uppercase;
        }

        .hero h1 {
            font-size: clamp(40px, 4vw, 68px);
            line-height: 1.08;
            letter-spacing: -2px;
            margin: 20px 0;
        }

        .hero h1 span {
            background: linear-gradient(
                90deg, #d8b4fe, #a78bfa
            );
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }

        .hero p {
            color: #c1b8d7;
            font-size: 17px;
            line-height: 1.8;
            max-width: 410px;
        }

        /* DISCO DECORATIVO */

        .record-area {
            height: 300px;
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
        }

        .record {
            width: 245px;
            height: 245px;
            border-radius: 50%;
            position: relative;
            display: flex;
            justify-content: center;
            align-items: center;
            background:
                repeating-radial-gradient(
                    circle,
                    #111119 0px,
                    #111119 3px,
                    #242032 4px,
                    #111119 6px
                );
            box-shadow:
                0 0 75px rgba(168, 85, 247, 0.35),
                0 30px 70px rgba(0, 0, 0, 0.5);
            border: 7px solid #171321;
            animation: spin 22s linear infinite;
        }

        .record::before {
            content: "♫";
            display: flex;
            align-items: center;
            justify-content: center;
            width: 94px;
            height: 94px;
            color: white;
            font-size: 43px;
            border-radius: 50%;
            background: linear-gradient(
                135deg, #b47aff, #6128ad
            );
            border: 5px solid #21132f;
        }

        .record::after {
            content: "";
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #181022;
            position: absolute;
        }

        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .hero-footer {
            position: relative;
            z-index: 2;
            color: #a59bb9;
            font-size: 12px;
        }

        /* PANEL DERECHO */

        .login-side {
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 50px 35px;
            background:
                radial-gradient(
                    ellipse at top right,
                    rgba(110, 45, 190, 0.09),
                    transparent 60%
                ),
                #0b0c15;
        }

        .login-card {
            width: 100%;
            max-width: 420px;
        }

        .login-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 9px 15px;
            border-radius: 30px;
            background: rgba(168, 85, 247, 0.1);
            border: 1px solid rgba(168, 85, 247, 0.2);
            color: #c4a2ff;
            font-size: 12px;
            font-weight: 600;
        }

        .login-card h2 {
            font-size: 36px;
            letter-spacing: -1px;
            margin: 25px 0 10px;
        }

        .login-subtitle {
            color: #9695aa;
            font-size: 15px;
            line-height: 1.7;
            margin-bottom: 36px;
        }

        /* FORMULARIO */

        .form-group {
            margin-bottom: 23px;
        }

        .form-label {
            display: block;
            margin-bottom: 10px;
            font-size: 13px;
            font-weight: 600;
            color: #dedde8;
        }

        .input-field {
            width: 100%;
            height: 53px;
            background: #151622;
            border: 1px solid #303044;
            border-radius: 12px;
            outline: none;
            padding: 0 17px;
            font-size: 14px;
            color: white;
            transition: all 0.2s ease;
        }

        .input-field::placeholder {
            color: #77778b;
        }

        .input-field:focus {
            border-color: #a855f7;
            background: #191727;
            box-shadow:
                0 0 0 4px rgba(168, 85, 247, 0.12);
        }

        .password-wrapper {
            position: relative;
        }

        .password-wrapper .input-field {
            padding-right: 95px;
        }

        .toggle-password {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            border: 0;
            background: transparent;
            color: #bba7d9;
            cursor: pointer;
            font-size: 12px;
            padding: 8px;
        }

        .toggle-password:hover {
            color: white;
        }

        /* BOTÓN */

        .btn-login {
            display: block;
            width: 100%;
            height: 54px;
            border: none;
            border-radius: 12px;
            margin-top: 30px;
            background: linear-gradient(
                110deg, #a855f7, #7c3aed
            );
            color: white;
            font-size: 15px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.2s ease;
            box-shadow:
                0 8px 28px rgba(124, 58, 237, 0.22);
        }

        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow:
                0 12px 35px rgba(124, 58, 237, 0.35);
        }

        .btn-login:active {
            transform: translateY(0);
        }

        /* MENSAJES Y REGISTRO */

        .error-message {
            display: block;
            color: #fda4af;
            font-size: 13px;
            line-height: 1.5;
        }

        .error-message:not(:empty) {
            margin-top: 18px;
            padding: 12px;
            border-radius: 9px;
            background: rgba(239, 68, 68, 0.08);
            border: 1px solid rgba(239, 68, 68, 0.2);
        }

        .signup-section {
            text-align: center;
            margin-top: 32px;
            padding-top: 25px;
            border-top: 1px solid #292939;
            color: #9695aa;
            font-size: 14px;
        }

        .signup-link {
            color: #c39aff;
            font-weight: 700;
            text-decoration: none;
            margin-left: 5px;
        }

        .signup-link:hover {
            color: white;
            text-decoration: underline;
        }

        .login-footer {
            margin-top: 45px;
            text-align: center;
            color: #646477;
            font-size: 12px;
        }

        /* RESPONSIVE */

        @media (max-width: 900px) {
            .login-page {
                grid-template-columns: 1fr;
            }

            .hero {
                padding: 25px;
                min-height: auto;
            }

            .hero-content,
            .record-area,
            .hero-footer {
                display: none;
            }

            .login-side {
                min-height: calc(100vh - 95px);
                padding: 35px 22px;
            }
        }

        @media (max-width: 480px) {
            .login-card h2 {
                font-size: 30px;
            }

            .brand {
                font-size: 22px;
            }

            .login-side {
                align-items: flex-start;
            }
        }

        @media (prefers-reduced-motion: reduce) {
            .record {
                animation: none;
            }

            .btn-login {
                transition: none;
            }
        }
    </style>
</head>

<body>
    <form id="formLogin" runat="server">

        <main class="login-page">

            <!-- PRESENTACIÓN IZQUIERDA -->
            <section class="hero">

                <div class="brand">
                    <div class="brand-icon">♫</div>
                    <div>Poli<span>Music</span></div>
                </div>

                <div class="hero-content">

                    <div class="eyebrow">
                        TU MÚSICA, TU MUNDO
                    </div>

                    <h1>
                        Cada momento
                        merece una
                        <span>gran canción.</span>
                    </h1>

                    <p>
                        Descubre, escucha y disfruta
                        tus canciones favoritas en un
                        solo lugar. Tu experiencia
                        musical comienza aquí.
                    </p>

                    <div class="record-area">
                        <div class="record"></div>
                    </div>

                </div>

                <div class="hero-footer">
                    © 2026 PoliMusic · Aplicaciones Web Avanzadas
                </div>

            </section>

            <!-- FORMULARIO DERECHO -->
            <section class="login-side">

                <div class="login-card">

                    <div class="login-badge">
                        ♪ BIENVENIDO A POLIMUSIC
                    </div>

                    <h2>Iniciar sesión</h2>

                    <p class="login-subtitle">
                        Ingresa a tu cuenta y continúa
                        disfrutando de tu música favorita.
                    </p>

                    <!-- USUARIO -->
                    <div class="form-group">

                        <asp:Label
                            runat="server"
                            AssociatedControlID="txtLogin"
                            CssClass="form-label"
                            Text="Nombre de usuario" />

                        <asp:TextBox
                            ID="txtLogin"
                            runat="server"
                            CssClass="input-field"
                            placeholder="Ingresa tu usuario"
                            MaxLength="50"
                            autocomplete="username">
                        </asp:TextBox>

                    </div>

                    <!-- CONTRASEÑA -->
                    <div class="form-group">

                        <asp:Label
                            runat="server"
                            AssociatedControlID="txtPassword"
                            CssClass="form-label"
                            Text="Contraseña" />

                        <div class="password-wrapper">

                            <asp:TextBox
                                ID="txtPassword"
                                runat="server"
                                CssClass="input-field"
                                TextMode="Password"
                                placeholder="Ingresa tu contraseña"
                                autocomplete="current-password">
                            </asp:TextBox>

                            <button
                                type="button"
                                class="toggle-password"
                                id="btnTogglePassword"
                                onclick="togglePassword()"
                                aria-label="Mostrar contraseña"
                                aria-pressed="false">
                                Mostrar
                            </button>

                        </div>
                    </div>

                    <!-- INICIAR SESIÓN -->
                    <asp:Button
                        ID="btnLogin"
                        runat="server"
                        Text="Iniciar sesión"
                        CssClass="btn-login"
                        OnClick="BtnLogin_Click" />

                    <!-- ERRORES -->
                    <asp:Label
                        ID="lblMessage"
                        runat="server"
                        CssClass="error-message"
                        role="alert">
                    </asp:Label>

                    <!-- REGISTRO -->
                    <div class="signup-section">

                        ¿Todavía no tienes una cuenta?

                        <asp:LinkButton
                            ID="LinkButtonNewUser"
                            runat="server"
                            CssClass="signup-link"
                            OnClick="LinkButtonNewUser_Click">
                            Regístrate gratis
                        </asp:LinkButton>

                    </div>

                    <div class="login-footer">
                        PoliMusic · Tu espacio musical
                    </div>

                </div>

            </section>

        </main>

    </form>

    <script type="text/javascript">
        function togglePassword() {
            var input = document.getElementById(
                '<%= txtPassword.ClientID %>'
            );

            var button = document.getElementById(
                'btnTogglePassword'
            );

            if (input.type === 'password') {
                input.type = 'text';
                button.textContent = 'Ocultar';
                button.setAttribute(
                    'aria-label', 'Ocultar contraseña'
                );
                button.setAttribute('aria-pressed', 'true');
            } else {
                input.type = 'password';
                button.textContent = 'Mostrar';
                button.setAttribute(
                    'aria-label', 'Mostrar contraseña'
                );
                button.setAttribute('aria-pressed', 'false');
            }
        }
    </script>

</body>
</html>



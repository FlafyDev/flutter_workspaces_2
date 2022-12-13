#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk-layer-shell/gtk-layer-shell.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;
};

static void respond(FlMethodCall *method_call, FlMethodResponse *response) {
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method call response: %s", error->message);
  }
}

static GtkWindow *window = nullptr;

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void method_call_cb(FlMethodChannel *channel, FlMethodCall *method_call,
                           gpointer user_data) {
  const gchar *method = fl_method_call_get_name(method_call);
  if (strcmp(method, "focusable") == 0) {
    FlValue *args = fl_method_call_get_args(method_call);
    FlValue *focusable = fl_value_lookup_string(args, "focusable");

    if (focusable != nullptr &&
        fl_value_get_type(focusable) == FL_VALUE_TYPE_BOOL) {
      gtk_layer_set_keyboard_mode(window,
                                  fl_value_get_bool(focusable)
                                      ? GTK_LAYER_SHELL_KEYBOARD_MODE_EXCLUSIVE
                                      : GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

      g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_null()));
      respond(method_call, response);
      return;
    }
  } else if (strcmp(method, "resize") == 0) {
    FlValue *args = fl_method_call_get_args(method_call);
    FlValue *height_value = fl_value_lookup_string(args, "height");

    if (height_value != nullptr &&
        fl_value_get_type(height_value) == FL_VALUE_TYPE_INT) {

      // cchange position
      /* gtk_window_set_position(window, GTK_WIN_POS_CENTER); */
      /* gtk_window_move(window, 100, 1080 - fl_value_get_int(height_value) -
       * 9); */
      /* gtk_window_move(window, 100, 100); */
      /* gtk_widget_set_size_request(GTK_WIDGET(window), 1920,
       * fl_value_get_int(height_value)); */
      /* gtk_window_set_position(window, GTK_WIN_POS_CENTER); */
      gtk_layer_set_margin(window, GTK_LAYER_SHELL_EDGE_BOTTOM,
                           fl_value_get_int(height_value) - 300);

      g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(
          fl_method_success_response_new(fl_value_new_null()));
      respond(method_call, response);
      return;
    }
  }

  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  g_autoptr(GError) error = nullptr;
  fl_method_call_respond(method_call, response, &error);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication *application) {
  window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gtk_layer_init_for_window(window);
  gtk_layer_set_layer(window, GTK_LAYER_SHELL_LAYER_TOP);
  /* gtk_layer_auto_exclusive_zone_enable (window); */
  gtk_layer_set_margin(window, GTK_LAYER_SHELL_EDGE_BOTTOM, 9 - 300);
  /* gtk_layer_set_margin (window, GTK_LAYER_SHELL_EDGE_RIGHT, 20); */
  /* gtk_layer_set_margin (window, GTK_LAYER_SHELL_EDGE_TOP, 20); */
  // Anchors are if the window is pinned to each edge of the output
  gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
  /* gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_TOP, TRUE); */
  /* gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_LEFT, TRUE); */
  /* gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_RIGHT, TRUE); */
  /* GtkWidget *label = gtk_label_new (""); */
  /* gtk_label_set_markup (GTK_LABEL (label), */
  /*                       "<span font_desc=\"20.0\">" */
  /*                           "GTK Layer Shell example!" */
  /*                       "</span>"); */
  /* gtk_container_add (GTK_CONTAINER (window), label); */
  /* gtk_container_set_border_width (GTK_CONTAINER (window), 12); */
  /* gtk_widget_show_all (GTK_WIDGET (window)); */
  gtk_widget_set_size_request(GTK_WIDGET(window), 1920, 300);

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = FALSE;
  if (use_header_bar) {
    GtkHeaderBar *header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "flutter_workspaces_2");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "flutter_workspaces_2");
  }

  /* gtk_window_set_default_size(window, 1280, 720); */
  /* gtk_widget_show_all(GTK_WIDGET(window)); */

  g_autoptr(FlDartProject) project = fl_dart_project_new();

  MyApplication *self = MY_APPLICATION(application);
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView *view = fl_view_new(project);
  /* gtk_widget_show(GTK_WIDGET(view)); */
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Get engine from view
  FlEngine *engine = fl_view_get_engine(view);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlBinaryMessenger) messenger =
      fl_engine_get_binary_messenger(engine);
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(messenger,
                            "general", // this is our channel name
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel,
      // Method which will be called when we call invokeMethod() from dart
      method_call_cb, g_object_ref(view), g_object_unref);

  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(view), g_object_unref);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication *application,
                                                  gchar ***arguments,
                                                  int *exit_status) {
  MyApplication *self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject *object) {
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {}

MyApplication *my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
